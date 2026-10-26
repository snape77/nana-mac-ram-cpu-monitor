import Foundation
import Darwin

struct CPUTicks {
    let user: UInt32
    let system: UInt32
    let idle: UInt32
    let nice: UInt32

    // HOST_CPU_LOAD_INFO sums all CPUs. Use interval deltas, not totals since boot.
    // Each counter is UInt32 and may wrap independently.
    static func usage(from previous: CPUTicks, to current: CPUTicks) -> Double? {
        let busy = UInt64(current.user &- previous.user)
            + UInt64(current.system &- previous.system) + UInt64(current.nice &- previous.nice)
        let total = busy + UInt64(current.idle &- previous.idle)
        guard total > 0 else { return nil }
        return 100 * Double(busy) / Double(total)
    }
}

struct CPUSnapshot: Codable {
    let usagePercent: Double?
    let intervalSeconds: TimeInterval?
    let level: PressureLevel

    init(usagePercent: Double? = nil, intervalSeconds: TimeInterval? = nil) {
        self.usagePercent = usagePercent
        self.intervalSeconds = intervalSeconds
        if let usagePercent {
            // Strict thresholds apply to unrounded usage, independently of RAM.
            level = usagePercent > 90 ? .critical : (usagePercent > 80 ? .warning : .normal)
        } else {
            level = .unknown
        }
    }

    var displayPercent: Int? { usagePercent.map { Int($0.rounded()) } }
}

struct CPUSampler {
    private var previous: (ticks: CPUTicks, time: TimeInterval)?
    private(set) var snapshot = CPUSnapshot()

    mutating func reset() {
        previous = nil
        snapshot = CPUSnapshot()
    }

    mutating func observe(_ ticks: CPUTicks?, at time: TimeInterval) -> CPUSnapshot {
        guard let ticks else {
            reset()
            return snapshot
        }
        if let previous {
            let interval = time - previous.time
            // Ignore rapid menu clicks, but accept slightly early 1-second ticks.
            if interval >= 0 && interval < 0.5 { return snapshot }
            // Rebaseline after sleep/long suspension or a clock discontinuity.
            if interval >= 0.5 && interval <= 30 {
                snapshot = CPUSnapshot(usagePercent: CPUTicks.usage(from: previous.ticks, to: ticks),
                                       intervalSeconds: interval)
            } else {
                snapshot = CPUSnapshot()
            }
        }
        previous = (ticks, time)
        return snapshot
    }
}

final class CPUReader {
    private let host = mach_host_self()
    private var sampler = CPUSampler()

    deinit { mach_port_deallocate(mach_task_self_, host) }

    func reset() { sampler.reset() }

    func read() -> CPUSnapshot {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(host, HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        let ticks = status == KERN_SUCCESS ? CPUTicks(
            user: info.cpu_ticks.0, system: info.cpu_ticks.1,
            idle: info.cpu_ticks.2, nice: info.cpu_ticks.3) : nil
        return sampler.observe(ticks, at: ProcessInfo.processInfo.systemUptime)
    }
}
