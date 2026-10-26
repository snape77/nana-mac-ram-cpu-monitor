import Foundation
import Darwin

enum PressureLevel: String, Codable {
    case normal, warning, critical, unknown

    // This sysctl exports NOTE_MEMORYSTATUS_* flags (1/2/4), not the
    // kernel's internal pressure enumeration (0/1/2/3).
    init(dispatchValue: Int32?) {
        switch dispatchValue {
        case 1: self = .normal
        case 2: self = .warning
        case 4: self = .critical
        default: self = .unknown
        }
    }

    var title: String {
        switch self {
        case .normal: return "正常"
        case .warning: return "偏高"
        case .critical: return "严重"
        case .unknown: return "暂不可用"
        }
    }
}

struct MemorySnapshot: Codable {
    let level: PressureLevel
    let pressurePercent: Int?
    let alertIndexPercent: Int?
    let physicalBytes: UInt64
    let usedBytes: UInt64?
    let compressedBytes: UInt64?
    let swapBytes: UInt64?

    init(level: PressureLevel, pressurePercent: Int?, physicalBytes: UInt64,
         usedBytes: UInt64?, compressedBytes: UInt64?, swapBytes: UInt64?) {
        self.level = level
        self.pressurePercent = pressurePercent
        // 100% means the warning reference (raw estimate 50%), not full RAM.
        // Values above 100% remain visible; colors still use the system level.
        self.alertIndexPercent = pressurePercent.map { $0 * 2 }
        self.physicalBytes = physicalBytes
        self.usedBytes = usedBytes
        self.compressedBytes = compressedBytes
        self.swapBytes = swapBytes
    }

    // A transparent estimate of compressor pressure, motivated by XNU's
    // AVAILABLE_NON_COMPRESSED_MEMORY / AVAILABLE_MEMORY pressure model.
    // Not an Activity Monitor percentage or a RAM utilization percentage.
    static func pressurePercent(active: UInt64, inactive: UInt64, free: UInt64,
                                speculative: UInt64, compressed: UInt64) -> Int? {
        let available = Double(active) + Double(inactive) + Double(free)
            + Double(speculative) + Double(compressed)
        guard available > 0 else { return nil }
        return min(100, max(0, Int((100 * Double(compressed) / available).rounded())))
    }
}

final class MemoryReader {
    private let host = mach_host_self()
    private let physical = ProcessInfo.processInfo.physicalMemory

    deinit { mach_port_deallocate(mach_task_self_, host) }

    func read() -> MemorySnapshot {
        var pressure: Int32 = 0
        var pressureSize = MemoryLayout<Int32>.size
        let result = sysctlbyname("kern.memorystatus_vm_pressure_level", &pressure, &pressureSize, nil, 0)
        let level = PressureLevel(dispatchValue: result == 0 ? pressure : nil)

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let status = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        var swap = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        let swapResult = sysctlbyname("vm.swapusage", &swap, &swapSize, nil, 0)

        guard status == KERN_SUCCESS else {
            return MemorySnapshot(level: level, pressurePercent: nil, physicalBytes: physical,
                                  usedBytes: nil, compressedBytes: nil,
                                  swapBytes: swapResult == 0 ? swap.xsu_used : nil)
        }
        let pageSize = UInt64(vm_kernel_page_size)
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        // App memory excludes purgeable pages; file cache is reclaimable.
        let appPages = UInt64(stats.internal_page_count) - min(UInt64(stats.internal_page_count), UInt64(stats.purgeable_count))
        let used = min(physical, appPages * pageSize + UInt64(stats.wire_count) * pageSize + compressed)
        return MemorySnapshot(
            level: level,
            pressurePercent: MemorySnapshot.pressurePercent(
                active: UInt64(stats.active_count), inactive: UInt64(stats.inactive_count),
                free: UInt64(stats.free_count), speculative: UInt64(stats.speculative_count),
                compressed: UInt64(stats.compressor_page_count)),
            physicalBytes: physical, usedBytes: used, compressedBytes: compressed,
            swapBytes: swapResult == 0 ? swap.xsu_used : nil)
    }
}
