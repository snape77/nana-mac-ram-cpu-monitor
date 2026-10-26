import AppKit

final class MonitorController: NSObject, NSMenuDelegate {
    private let reader = MemoryReader()
    private let cpuReader = CPUReader()
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var refreshInterval = RefreshInterval.load()
    private var intervalItems: [NSMenuItem] = []
    private let intervalMenuItem = NSMenuItem()
    private let refreshInfoItem = NSMenuItem()
    private var snapshot: MemorySnapshot?
    private var cpuSnapshot = CPUSnapshot()
    private var renderedState: BadgeState?
    private let pressureItem = NSMenuItem()
    private let cpuItem = NSMenuItem()
    private let usedItem = NSMenuItem()
    private let compressedItem = NSMenuItem()
    private let swapItem = NSMenuItem()

    func start() {
        statusItem = NSStatusBar.system.statusItem(withLength: Badge.itemWidth)
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.imageScaling = .scaleNone
        statusItem.button?.setAccessibilityLabel("RAM Monitor · 上行 RAM，下行 CPU")
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "RAM Monitor · 上行 RAM / 下行 CPU", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        [pressureItem, cpuItem, usedItem, compressedItem, swapItem].forEach { menu.addItem($0) }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "警戒指数：100% 为黄色警戒参考线，可超过 100%", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "系统有滞回，变色不固定发生在 100%", action: nil, keyEquivalent: ""))
        menu.addItem(refreshInfoItem)
        menu.addItem(NSMenuItem(title: "CPU：>80% 黄色，>90% 红色", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        let intervalMenu = NSMenu(title: "刷新频率")
        for interval in RefreshInterval.allCases {
            let title = interval == .five ? "5 秒（默认）" : "\(interval.rawValue) 秒"
            let item = NSMenuItem(title: title, action: #selector(selectRefreshInterval(_:)), keyEquivalent: "")
            item.target = self
            item.tag = interval.rawValue
            intervalMenu.addItem(item)
            intervalItems.append(item)
        }
        intervalMenuItem.submenu = intervalMenu
        menu.addItem(intervalMenuItem)
        updateIntervalMenu()
        addAction("打开活动监视器", selector: #selector(openActivityMonitor), to: menu)
        addAction("立即刷新", selector: #selector(refresh), to: menu)
        menu.addItem(.separator())
        addAction("退出 RAM Monitor", selector: #selector(quit), to: menu, key: "q")
        statusItem.menu = menu
        refresh()
        restartTimer()
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(didWake),
            name: NSWorkspace.didWakeNotification, object: nil)
    }

    private func restartTimer() {
        // Switching intervals replaces the single timer rather than adding one.
        timer?.invalidate()
        let next = Timer(timeInterval: refreshInterval.seconds, repeats: true) { [weak self] _ in self?.refresh() }
        next.tolerance = min(1, refreshInterval.seconds * 0.1)
        RunLoop.main.add(next, forMode: .common)
        timer = next
    }

    private func updateIntervalMenu() {
        intervalMenuItem.title = "刷新频率：\(refreshInterval.rawValue) 秒"
        refreshInfoItem.title = "RAM 颜色跟随 macOS · 每 \(refreshInterval.rawValue) 秒更新"
        for item in intervalItems {
            item.state = item.tag == refreshInterval.rawValue ? .on : .off
        }
    }

    @objc private func selectRefreshInterval(_ sender: NSMenuItem) {
        guard let selected = RefreshInterval(rawValue: sender.tag), selected != refreshInterval else { return }
        refreshInterval = selected
        selected.save()
        restartTimer()
        updateIntervalMenu()
        refresh()
    }

    private func addAction(_ title: String, selector: Selector, to menu: NSMenu, key: String = "") {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }

    @objc private func refresh() {
        let next = reader.read()
        snapshot = next
        cpuSnapshot = cpuReader.read()
        let state = BadgeState(ramPercent: next.alertIndexPercent, ramLevel: next.level,
                               cpuPercent: cpuSnapshot.displayPercent, cpuLevel: cpuSnapshot.level)
        if renderedState != state {
            statusItem.button?.image = Badge.image(state)
            renderedState = state
        }
        let percent = next.alertIndexPercent.map { "\($0)%" } ?? "--%"
        statusItem.button?.toolTip = "上行 RAM：\(next.level.title) · 警戒指数 \(percent)\n下行 CPU：\(cpuText)（全机，采样间隔平均）\nRAM：100% 为黄色警戒参考线，颜色跟随 macOS\nCPU：超过 80% 黄色，超过 90% 红色\n点击查看详情"
        statusItem.button?.setAccessibilityValue("RAM \(next.level.title)，警戒指数 \(percent)；CPU \(cpuText)")
        updateMenu()
    }

    @objc private func didWake() {
        cpuReader.reset()
        refresh()
    }

    private var cpuText: String {
        cpuSnapshot.usagePercent.map { String(format: "%.1f%%", $0) } ?? "等待采样"
    }

    private func updateMenu() {
        guard let snapshot else { return }
        let percent = snapshot.alertIndexPercent.map { "\($0)%" } ?? "--%"
        pressureItem.title = "系统压力：\(snapshot.level.title) · 警戒指数 \(percent)"
        cpuItem.title = "CPU 使用率：\(cpuText) · 全机 0–100%"
        usedItem.title = "已用内存：\(gib(snapshot.usedBytes)) / \(gib(snapshot.physicalBytes))"
        compressedItem.title = "压缩内存：\(gib(snapshot.compressedBytes))"
        swapItem.title = "交换空间：\(gib(snapshot.swapBytes))"
    }

    private func gib(_ bytes: UInt64?) -> String {
        guard let bytes else { return "—" }
        return String(format: "%.1f GB", Double(bytes) / 1_073_741_824)
    }

    func menuWillOpen(_ menu: NSMenu) { refresh() }
    @objc private func openActivityMonitor() {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.ActivityMonitor") {
            NSWorkspace.shared.openApplication(at: url, configuration: .init())
        }
    }
    @objc private func quit() { NSApp.terminate(nil) }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let controller = MonitorController()
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller.start()
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

if CommandLine.arguments.contains("--sample") {
    // Keep existing memory fields; add a CPU interval sample for diagnostics.
    let cpu = CPUReader()
    _ = cpu.read()
    Thread.sleep(forTimeInterval: 2)
    var output = try JSONSerialization.jsonObject(with: JSONEncoder().encode(MemoryReader().read())) as! [String: Any]
    output["cpu"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(cpu.read()))
    let data = try JSONSerialization.data(withJSONObject: output, options: [.sortedKeys])
    print(String(decoding: data, as: UTF8.self))
} else if let index = CommandLine.arguments.firstIndex(of: "--render-previews"),
          CommandLine.arguments.count > index + 1 {
    let directory = URL(fileURLWithPath: CommandLine.arguments[index + 1], isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    _ = NSApplication.shared
    let cases: [(String, Int?, PressureLevel, Double?)] = [
        ("normal", 40, .normal, 12), ("cpu-warning", 40, .normal, 85),
        ("cpu-critical", 40, .normal, 95), ("ram-warning", 90, .warning, 20),
        ("maximum", 200, .critical, 100), ("unavailable", nil, .unknown, nil)
    ]
    for (name, ramPercent, ramLevel, cpuPercent) in cases {
        let cpu = CPUSnapshot(usagePercent: cpuPercent)
        let badge = Badge.image(BadgeState(ramPercent: ramPercent, ramLevel: ramLevel,
                                          cpuPercent: cpu.displayPercent, cpuLevel: cpu.level))
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 320, pixelsHigh: 220,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        bitmap.size = Badge.size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        badge.draw(in: NSRect(origin: .zero, size: Badge.size))
        NSGraphicsContext.restoreGraphicsState()
        try bitmap.representation(using: .png, properties: [:])!.write(
            to: directory.appendingPathComponent("\(name).png"))
    }
} else {
    let app = NSApplication.shared
    // Reopening the app must not add another status item.
    let others = NSRunningApplication.runningApplications(withBundleIdentifier: "org.nana.ram-cpu-monitor")
    if others.contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) { exit(0) }
    let delegate = AppDelegate()
    app.delegate = delegate
    withExtendedLifetime(delegate) { app.run() }
}
