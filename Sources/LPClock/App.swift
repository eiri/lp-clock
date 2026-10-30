import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let toggleItem = NSMenuItem(title: "On", action: #selector(toggle), keyEquivalent: "")
    private var status = "Starting…"
    private var timer: Timer?
    private var launchpad: Launchpad?
    private var enabled = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "text.redaction", accessibilityDescription: "LP Clock")

        let menu = NSMenu()
        toggleItem.target = self
        menu.addItem(toggleItem)

        let quit = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu

        // Poll for reconnects and use wall time so sleep does not cause clock drift.
        timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer!, forMode: .common)
        tick()
    }

    @objc private func toggle() {
        enabled.toggle()
        if enabled {
            tick()
        } else {
            do {
                try launchpad?.stop()
                status = "Off · Programmer mode disabled"
            } catch {
                status = error.localizedDescription
            }
            updateMenu()
        }
    }

    private func tick() {
        guard enabled else { return }
        do {
            if launchpad == nil { launchpad = try Launchpad() }
            let connected = try launchpad!.show(ClockFrame(date: Date()))
            status = connected ? "Launchpad Mini MK3 connected" : "Waiting for Launchpad Mini MK3…"
        } catch {
            status = error.localizedDescription
        }
        updateMenu()
    }

    private func updateMenu() {
        toggleItem.title = enabled ? "On" : "Off"
        toggleItem.state = enabled ? .on : .off
        statusItem.button?.appearsDisabled = !enabled
        statusItem.button?.toolTip = "LP Clock: \(status)"
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        try? launchpad?.stop()
    }
}
