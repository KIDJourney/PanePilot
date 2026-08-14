import AppKit
import ApplicationServices
import PanePilotCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var hotKeyManager: HotKeyManager?
    private var commander: WindowCommander?
    private let shortcutStore = ShortcutStore()
    private var preferencesWindowController: PreferencesWindowController?
    private var accessibilityMenuItem: NSMenuItem?
    private var checkForUpdatesMenuItem: NSMenuItem?
    private var updateController: UpdateController?

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
        let updateController = UpdateController { [weak self] isChecking in
            self?.checkForUpdatesMenuItem?.title = L10n.text(
                isChecking ? "Checking for Updates..." : "Check for Updates..."
            )
            self?.checkForUpdatesMenuItem?.isEnabled = !isChecking
        }
        self.updateController = updateController
        updateController.start()
        commander.requestAccessibilityPermission(prompt: false)
    }

    private func buildStatusMenu() {
        let item = statusItem ?? NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "PanePilot") {
            image.isTemplate = true
            item.button?.image = image
            item.button?.imagePosition = .imageOnly
        } else {
            item.button?.title = "PP"
        }
        item.button?.toolTip = "PanePilot"
        statusItem = item

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        menu.addItem(menuItem(title: L10n.text("About PanePilot"), action: #selector(showAbout), imageName: "info.circle"))

        let accessibilityItem = menuItem(
            title: "",
            action: #selector(requestPermission),
            imageName: "lock.shield"
        )
        accessibilityMenuItem = accessibilityItem
        updateAccessibilityMenuItem()
        menu.addItem(accessibilityItem)
        menu.addItem(menuItem(title: L10n.text("Settings..."), action: #selector(openPreferences), keyEquivalent: ",", imageName: "gearshape"))
        let isChecking = updateController?.isChecking == true
        let updateItem = menuItem(
            title: L10n.text(isChecking ? "Checking for Updates..." : "Check for Updates..."),
            action: #selector(checkForUpdates),
            imageName: "arrow.triangle.2.circlepath"
        )
        updateItem.isEnabled = !isChecking
        checkForUpdatesMenuItem = updateItem
        menu.addItem(updateItem)
        menu.addItem(.separator())

        let shortcuts = Dictionary(uniqueKeysWithValues: shortcutStore.resolvedShortcuts().map { ($0.action, $0) })
        for (sectionIndex, actions) in WindowAction.menuSections.enumerated() {
            for action in actions {
                menu.addItem(actionMenuItem(action, shortcut: shortcuts[action]))
            }
            if sectionIndex < WindowAction.menuSections.count - 1 {
                menu.addItem(.separator())
            }
        }

        menu.addItem(.separator())
        menu.addItem(menuItem(title: L10n.text("Quit PanePilot"), action: #selector(quit), keyEquivalent: "q", imageName: "power"))
        item.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateAccessibilityMenuItem()
    }

    private func updateAccessibilityMenuItem() {
        let isTrusted = AXIsProcessTrusted()
        accessibilityMenuItem?.title = L10n.text(
            isTrusted ? "Accessibility Granted" : "Grant Accessibility Access..."
        )
        accessibilityMenuItem?.image = NSImage(
            systemSymbolName: isTrusted ? "checkmark.shield" : "lock.shield",
            accessibilityDescription: L10n.text(
                isTrusted ? "Accessibility granted" : "Grant Accessibility access"
            )
        )
        accessibilityMenuItem?.isEnabled = !isTrusted
    }

    private func menuItem(
        title: String,
        action: Selector,
        keyEquivalent: String = "",
        imageName: String? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        if let imageName {
            item.image = NSImage(systemSymbolName: imageName, accessibilityDescription: title)
        }
        return item
    }

    private func actionMenuItem(_ action: WindowAction, shortcut: KeyboardShortcut?) -> NSMenuItem {
        let item = menuItem(title: action.localizedMenuTitle, action: #selector(runMenuAction(_:)))
        item.representedObject = action.rawValue
        if let shortcut, let keyEquivalent = shortcut.menuKeyEquivalent {
            item.keyEquivalent = keyEquivalent
            item.keyEquivalentModifierMask = shortcut.eventModifierFlags
        }
        return item
    }

    @objc private func requestPermission() {
        commander?.requestAccessibilityPermission(prompt: true)
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "PanePilot",
            .applicationIcon: NSApp.applicationIconImage ?? NSImage(),
            .credits: NSAttributedString(string: L10n.text("Keyboard-first window arrangement for macOS."))
        ])
        NSApp.activate()
    }

    @objc private func openPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(
                store: shortcutStore,
                onRecordingChanged: { [weak self] isRecording in
                    self?.hotKeyManager?.setSuspended(isRecording)
                },
                onShortcutsChanged: { [weak self] in
                    self?.reloadShortcuts()
                }
            )
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

    @objc private func checkForUpdates() {
        updateController?.checkForUpdates(userInitiated: true)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

extension WindowAction {
    static let menuSections: [[WindowAction]] = [
        [.center, .maximize],
        [.leftHalf, .rightHalf, .topHalf, .bottomHalf],
        [.upperLeft, .lowerLeft, .upperRight, .lowerRight],
        [.nextThird, .previousThird, .larger, .smaller],
        [.nextDisplay, .previousDisplay],
        [.undo, .redo]
    ]

    static let menuOrder: [WindowAction] = menuSections.flatMap { $0 }
}
