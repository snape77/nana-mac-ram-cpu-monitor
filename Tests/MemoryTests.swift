import Foundation

@main
struct MemoryTests {
    static func main() {
        precondition(PressureLevel(dispatchValue: 1) == .normal)
        precondition(PressureLevel(dispatchValue: 2) == .warning)
        precondition(PressureLevel(dispatchValue: 4) == .critical)
        precondition(PressureLevel(dispatchValue: nil) == .unknown)
        precondition(PressureLevel(dispatchValue: 0) == .unknown)
        precondition(PressureLevel(dispatchValue: 3) == .unknown)
        let percent = MemorySnapshot.pressurePercent
        precondition(percent(0, 0, 0, 0, 0) == nil)
        precondition(percent(100, 100, 100, 100, 0) == 0)
        precondition(percent(100, 100, 100, 100, 400) == 50)
        precondition(percent(0, 0, 0, 0, 400) == 100)
        precondition(percent(1, 1, 1, 0, 1) == 25)
        precondition(percent(UInt64.max, UInt64.max, UInt64.max, UInt64.max, UInt64.max) == 20)
        // User-approved scale: do not clamp at 100 or derive colors from it.
        for (raw, expected) in [(20, 40), (45, 90), (50, 100), (60, 120), (100, 200)] {
            let snapshot = MemorySnapshot(level: .normal, pressurePercent: raw,
                physicalBytes: 0, usedBytes: nil, compressedBytes: nil, swapBytes: nil)
            precondition(snapshot.alertIndexPercent == expected)
            precondition(snapshot.level == .normal)
        }
        let unavailable = MemorySnapshot(level: .unknown, pressurePercent: nil,
            physicalBytes: 0, usedBytes: nil, compressedBytes: nil, swapBytes: nil)
        precondition(unavailable.alertIndexPercent == nil)
        let sample = MemorySnapshot(level: .warning, pressurePercent: 45,
            physicalBytes: 0, usedBytes: nil, compressedBytes: nil, swapBytes: nil)
        let json = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(sample)) as! [String: Any]
        precondition(json["pressurePercent"] as? Int == 45 && json["alertIndexPercent"] as? Int == 90)
        print("PASS: 24 checks including alert scaling, >100%, missing data, independent colors, and diagnostic JSON")
    }
}
