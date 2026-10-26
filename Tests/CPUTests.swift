import Foundation

@main
struct CPUTests {
    static func main() {
        let zero = CPUTicks(user: 0, system: 0, idle: 0, nice: 0)
        precondition(CPUTicks.usage(from: zero, to: zero) == nil)
        precondition(CPUTicks.usage(from: zero, to: .init(user: 0, system: 0, idle: 100, nice: 0)) == 0)
        precondition(CPUTicks.usage(from: zero, to: .init(user: 50, system: 25, idle: 0, nice: 25)) == 100)
        precondition(CPUTicks.usage(from: zero, to: .init(user: 20, system: 10, idle: 60, nice: 10)) == 40)
        // Busy cumulative history must not dominate an idle current interval.
        precondition(CPUTicks.usage(from: .init(user: 1000, system: 1000, idle: 0, nice: 0),
                                   to: .init(user: 1000, system: 1000, idle: 100, nice: 0)) == 0)
        precondition(CPUTicks.usage(from: .init(user: UInt32.max - 1, system: 0, idle: UInt32.max - 1, nice: 0),
                                   to: .init(user: 2, system: 0, idle: 2, nice: 0)) == 50)
        // All-core totals still normalize to 0...100, regardless of core count.
        precondition(CPUTicks.usage(from: zero, to: .init(user: 4000, system: 0, idle: 4000, nice: 0)) == 50)
        for (value, level) in [(0.0, PressureLevel.normal), (80, .normal), (80.01, .warning),
                               (90, .warning), (90.01, .critical), (100, .critical)] {
            precondition(CPUSnapshot(usagePercent: value).level == level)
        }
        precondition(CPUSnapshot().level == .unknown)
        var sampler = CPUSampler()
        precondition(sampler.observe(zero, at: 0).usagePercent == nil)
        let half = CPUTicks(user: 50, system: 0, idle: 50, nice: 0)
        precondition(sampler.observe(half, at: 5).usagePercent == 50)
        precondition(sampler.observe(half, at: 5.1).usagePercent == 50)
        precondition(sampler.observe(nil, at: 10).usagePercent == nil)
        precondition(sampler.observe(half, at: 15).usagePercent == nil)
        precondition(sampler.observe(.init(user: 150, system: 0, idle: 50, nice: 0), at: 20).usagePercent == 100)
        sampler.reset()
        precondition(sampler.observe(zero, at: 25).usagePercent == nil)
        precondition(sampler.observe(half, at: 60).usagePercent == nil)
        precondition(sampler.observe(.init(user: 100, system: 0, idle: 100, nice: 0), at: 65).usagePercent == 50)
        precondition(sampler.observe(half, at: 64).usagePercent == nil)
        // A 1-second timer can fire slightly early; it must not update every other tick.
        sampler.reset()
        precondition(sampler.observe(zero, at: 0).usagePercent == nil)
        precondition(sampler.observe(half, at: 0.95).usagePercent == 50)
        precondition(sampler.observe(.init(user: 100, system: 0, idle: 200, nice: 0), at: 1.95).usagePercent == 25)
        print("PASS: 27 CPU checks including 1-second timer jitter, interval deltas, thresholds, and recovery")
    }
}
