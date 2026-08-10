import AppKit
import PanePilotCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var hotKeyManager: HotKeyManager?
    private var commander: WindowCommander?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let windowClient = AccessibilityWindowClient()
        let commander = WindowCommander(windowClient: windowClient)
        self.commander = commander

        let hotKeyManager = HotKeyManager()
        self.hotKeyManager = hotKeyManager
        hotKeyManager.actionHandler = { [weak commander] action in
            Task { @MainActor in
                commander?.perform(action)
            }
        }
        hotKeyManager.registerDefaults()

        buildStatusMenu(commander: commander)
        commander.requestAccessibilityPermission(prompt: false)
    }

    private func buildStatusMenu(commander: WindowCommander) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "PanePilot"
        statusItem = item

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Request Accessibility Permission", action: #selector(requestPermission), keyEquivalent: ""))
        menu.addItem(.separator())

        for action in WindowAction.menuOrder {
            let menuItem = NSMenuItem(
                title: "\(action.menuTitle)  \(HotKeyManager.shortcutLabel(for: action) ?? "")",
                action: #selector(runMenuAction(_:)),
                keyEquivalent: ""
            )
            menuItem.representedObject = action.rawValue
            menu.addItem(menuItem)
        }

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit PanePilot", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
    }

    @objc private func requestPermission() {
        commander?.requestAccessibilityPermission(prompt: true)
    }

    @objc private func runMenuAction(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let action = WindowAction(rawValue: rawValue)
        else {
            return
        }
        commander?.perform(action)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

private extension WindowAction {
    static let menuOrder: [WindowAction] = [
        .center,
        .maximize,
        .leftHalf,
        .rightHalf,
        .topHalf,
        .bottomHalf,
        .upperLeft,
        .lowerLeft,
        .upperRight,
        .lowerRight,
        .nextThird,
        .previousThird,
        .larger,
        .smaller,
        .nextDisplay,
        .previousDisplay,
        .undo,
        .redo
    ]
}
