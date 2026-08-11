import AppKit
import PanePilotCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var hotKeyManager: HotKeyManager?
    private var commander: WindowCommander?
    private let shortcutStore = ShortcutStore()
    private var preferencesWindowController: PreferencesWindowController?

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
        hotKeyManager.register(shortcuts: shortcutStore.resolvedShortcuts())

        buildStatusMenu()
        commander.requestAccessibilityPermission(prompt: false)
    }

    private func buildStatusMenu() {
        let item = statusItem ?? NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "PanePilot"
        statusItem = item

        let menu = NSMenu()
        menu.addItem(menuItem(title: "Request Accessibility Permission", action: #selector(requestPermission)))
        menu.addItem(menuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(.separator())

        let shortcutLabels = Dictionary(
            uniqueKeysWithValues: shortcutStore.resolvedShortcuts().map { ($0.action, $0.label) }
        )
        for action in WindowAction.menuOrder {
            let shortcutSuffix = shortcutLabels[action].map { "  \($0)" } ?? ""
            let item = menuItem(
                title: "\(action.menuTitle)\(shortcutSuffix)",
                action: #selector(runMenuAction(_:))
            )
            item.representedObject = action.rawValue
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Quit PanePilot", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
    }

    private func menuItem(title: String, action: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    @objc private func requestPermission() {
        commander?.requestAccessibilityPermission(prompt: true)
    }

    @objc private func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(store: shortcutStore) { [weak self] in
                self?.reloadShortcuts()
            }
        }
        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate()
    }

    private func reloadShortcuts() {
        hotKeyManager?.register(shortcuts: shortcutStore.resolvedShortcuts())
        buildStatusMenu()
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

extension WindowAction {
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
