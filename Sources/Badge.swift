import AppKit

struct BadgeState: Equatable {
    let ramPercent: Int?
    let ramLevel: PressureLevel
    let cpuPercent: Int?
    let cpuLevel: PressureLevel
}

enum Badge {
    static let itemWidth: CGFloat = 36
    static let size = NSSize(width: 32, height: 22)

    static func color(_ level: PressureLevel) -> NSColor {
        switch level {
        case .normal: return NSColor(srgbRed: 0.12, green: 0.52, blue: 0.28, alpha: 1)
        case .warning: return NSColor(srgbRed: 0.72, green: 0.51, blue: 0.00, alpha: 1)
        case .critical: return NSColor(srgbRed: 0.83, green: 0.19, blue: 0.20, alpha: 1)
        case .unknown: return NSColor(srgbRed: 0.40, green: 0.43, blue: 0.47, alpha: 1)
        }
    }

    static func image(_ state: BadgeState) -> NSImage {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 8.2, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let image = NSImage(size: size, flipped: false) { _ in
            // AppKit coordinates are bottom-up: RAM above, CPU below.
            for (percent, level, y) in [(state.ramPercent, state.ramLevel, CGFloat(11.5)),
                                       (state.cpuPercent, state.cpuLevel, CGFloat(0.5))] {
                let text = percent.map { "\($0)%" } ?? "--%"
                let textSize = (text as NSString).size(withAttributes: attrs)
                color(level).withAlphaComponent(0.5).setFill()
                NSBezierPath(roundedRect: NSRect(x: 0, y: y, width: 32, height: 10),
                             xRadius: 2.5, yRadius: 2.5).fill()
                (text as NSString).draw(at: NSPoint(x: (32 - textSize.width) / 2,
                                                  y: y + (10 - textSize.height) / 2), withAttributes: attrs)
            }
            return true
        }
        image.isTemplate = false
        return image
    }
}
