import AppKit
import Carbon
import PanePilotCore
import ServiceManagement

private final class SettingsBackgroundView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        dirtyRect.fill()
    }
}

@MainActor
final class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    private struct ActionGroup {
        let title: String
        let actions: [WindowAction]
    }

    private let store: ShortcutStore
    private let onRecordingChanged: (Bool) -> Void
    private let onShortcutsChanged: () -> Void
    private let loginItemController: LoginItemController
    private let groups: [ActionGroup] = [
        .init(title: L10n.text("GENERAL"), actions: [.center, .maximize]),
        .init(title: L10n.text("HALVES"), actions: [.leftHalf, .rightHalf, .topHalf, .bottomHalf]),
        .init(title: L10n.text("CORNERS"), actions: [.upperLeft, .lowerLeft, .upperRight, .lowerRight]),
        .init(title: L10n.text("THIRDS & SIZING"), actions: [.nextThird, .previousThird, .larger, .smaller]),
        .init(title: L10n.text("DISPLAYS & HISTORY"), actions: [.nextDisplay, .previousDisplay, .undo, .redo])
    ]
    private let statusLabel = NSTextField(labelWithString: "")
    private let statusDot = NSView()
    private let launchAtLoginSwitch = NSSwitch()
    private let launchAtLoginDescription = NSTextField(labelWithString: "")
    private let openLoginItemsButton = NSButton(title: L10n.text("Open System Settings"), target: nil, action: nil)
    private var shortcutButtons: [WindowAction: NSButton] = [:]
    private var clearButtons: [WindowAction: NSButton] = [:]
    private var eventMonitor: Any?
    private var recordingAction: WindowAction?

    init(
        store: ShortcutStore,
        loginItemController: LoginItemController = LoginItemController(),
        onRecordingChanged: @escaping (Bool) -> Void = { _ in },
        onShortcutsChanged: @escaping () -> Void
    ) {
        self.store = store
        self.loginItemController = loginItemController
        self.onRecordingChanged = onRecordingChanged
        self.onShortcutsChanged = onShortcutsChanged

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.text("PanePilot Settings")
        window.minSize = NSSize(width: 620, height: 520)
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        window.delegate = self
        window.contentView = buildContentView()
        refreshRows()
        refreshLoginItem()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func close() {
        stopRecording()
        super.close()
    }

    func windowWillClose(_ notification: Notification) {
        stopRecording()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        refreshLoginItem()
    }

    func renderSnapshot(to url: URL) -> Bool {
        guard let contentView = window?.contentView else { return false }
        contentView.layoutSubtreeIfNeeded()
        guard let bitmap = contentView.bitmapImageRepForCachingDisplay(in: contentView.bounds) else {
            return false
        }
        contentView.cacheDisplay(in: contentView.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            return false
        }
        do {
            try data.write(to: url)
            return true
        } catch {
            NSLog("PanePilot could not write settings snapshot: \(error)")
            return false
        }
    }

    private func buildContentView() -> NSView {
        let root = SettingsBackgroundView()

        let header = buildHeader()
        let headerSeparator = separator()
        let scrollView = buildShortcutList()
        let footerSeparator = separator()
        let footer = buildFooter()

        for view in [header, headerSeparator, scrollView, footerSeparator, footer] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }

        NSLayoutConstraint.activate([
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            header.topAnchor.constraint(equalTo: root.topAnchor),
            header.heightAnchor.constraint(equalToConstant: 78),

            headerSeparator.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            headerSeparator.topAnchor.constraint(equalTo: header.bottomAnchor),

            scrollView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: headerSeparator.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: footerSeparator.topAnchor),

            footerSeparator.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            footerSeparator.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            footerSeparator.bottomAnchor.constraint(equalTo: footer.topAnchor),

            footer.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            footer.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            footer.heightAnchor.constraint(equalToConstant: 58)
        ])

        return root
    }

    private func buildHeader() -> NSView {
        let header = NSView()

        let iconView = NSImageView()
        iconView.image = NSApp.applicationIconImage ?? NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "PanePilot")
        iconView.imageScaling = .scaleProportionallyUpOrDown

        let titleLabel = NSTextField(labelWithString: L10n.text("PanePilot Settings"))
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)

        let textStack = NSStackView(views: [titleLabel])
        textStack.orientation = .vertical
        textStack.alignment = .leading

        iconView.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(iconView)
        header.addSubview(textStack)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 24),
            iconView.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 52),
            iconView.heightAnchor.constraint(equalToConstant: 52),
            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -24),
            textStack.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])

        return header
    }

    private func buildShortcutList() -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 16
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 24, bottom: 20, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(buildStartupGroup())
        for group in groups {
            stack.addArrangedSubview(buildGroup(group))
        }

        scrollView.documentView = stack
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor)
        ])
        return scrollView
    }

    private func buildGroup(_ group: ActionGroup) -> NSView {
        let section = NSStackView()
        section.orientation = .vertical
        section.alignment = .leading
        section.spacing = 0

        let title = NSTextField(labelWithString: group.title)
        title.font = .systemFont(ofSize: 11, weight: .semibold)
        title.textColor = .secondaryLabelColor
        title.translatesAutoresizingMaskIntoConstraints = false
        section.addArrangedSubview(title)
        section.setCustomSpacing(7, after: title)

        for (index, action) in group.actions.enumerated() {
            if index > 0 {
                let rowSeparator = separator()
                section.addArrangedSubview(rowSeparator)
                rowSeparator.widthAnchor.constraint(equalTo: section.widthAnchor).isActive = true
            }
            let row = buildActionRow(action)
            section.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: section.widthAnchor).isActive = true
        }

        return section
    }

    private func buildStartupGroup() -> NSView {
        let section = NSStackView()
        section.orientation = .vertical
        section.alignment = .leading
        section.spacing = 0

        let title = NSTextField(labelWithString: L10n.text("STARTUP"))
        title.font = .systemFont(ofSize: 11, weight: .semibold)
        title.textColor = .secondaryLabelColor
        section.addArrangedSubview(title)
        section.setCustomSpacing(7, after: title)

        let row = NSView()
        let label = NSTextField(labelWithString: L10n.text("Launch at Login"))
        label.font = .systemFont(ofSize: 13)

        launchAtLoginSwitch.target = self
        launchAtLoginSwitch.action = #selector(toggleLaunchAtLogin(_:))
        launchAtLoginSwitch.toolTip = L10n.text("Open PanePilot automatically when you log in")

        for view in [label, launchAtLoginSwitch] {
            view.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(view)
        }

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 42),
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            launchAtLoginSwitch.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            launchAtLoginSwitch.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        launchAtLoginDescription.font = .systemFont(ofSize: 12)
        launchAtLoginDescription.textColor = .secondaryLabelColor
        launchAtLoginDescription.lineBreakMode = .byWordWrapping
        launchAtLoginDescription.maximumNumberOfLines = 2

        openLoginItemsButton.bezelStyle = .rounded
        openLoginItemsButton.controlSize = .small
        openLoginItemsButton.target = self
        openLoginItemsButton.action = #selector(openLoginItemsSettings)

        let detailRow = NSView()
        launchAtLoginDescription.translatesAutoresizingMaskIntoConstraints = false
        openLoginItemsButton.translatesAutoresizingMaskIntoConstraints = false
        detailRow.addSubview(launchAtLoginDescription)
        detailRow.addSubview(openLoginItemsButton)

        NSLayoutConstraint.activate([
            detailRow.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
            launchAtLoginDescription.leadingAnchor.constraint(equalTo: detailRow.leadingAnchor),
            launchAtLoginDescription.topAnchor.constraint(equalTo: detailRow.topAnchor, constant: 3),
            launchAtLoginDescription.bottomAnchor.constraint(lessThanOrEqualTo: detailRow.bottomAnchor, constant: -3),
            launchAtLoginDescription.trailingAnchor.constraint(lessThanOrEqualTo: openLoginItemsButton.leadingAnchor, constant: -12),
            openLoginItemsButton.trailingAnchor.constraint(equalTo: detailRow.trailingAnchor),
            openLoginItemsButton.topAnchor.constraint(equalTo: detailRow.topAnchor),
            openLoginItemsButton.widthAnchor.constraint(equalToConstant: 146)
        ])

        section.addArrangedSubview(row)
        row.widthAnchor.constraint(equalTo: section.widthAnchor).isActive = true
        section.addArrangedSubview(detailRow)
        detailRow.widthAnchor.constraint(equalTo: section.widthAnchor).isActive = true
        return section
    }

    private func buildActionRow(_ action: WindowAction) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let actionLabel = NSTextField(labelWithString: action.localizedMenuTitle)
        actionLabel.font = .systemFont(ofSize: 13)
        actionLabel.lineBreakMode = .byTruncatingTail

        let shortcutButton = NSButton(title: "", target: self, action: #selector(beginRecording(_:)))
        shortcutButton.bezelStyle = .rounded
        shortcutButton.controlSize = .regular
        shortcutButton.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        shortcutButton.tag = actionIndex(action)
        shortcutButton.toolTip = L10n.format("Record a shortcut for %@", action.localizedMenuTitle)
        shortcutButtons[action] = shortcutButton

        let clearButton = NSButton(
            image: NSImage(
                systemSymbolName: "xmark.circle.fill",
                accessibilityDescription: L10n.format("Clear %@", action.localizedMenuTitle)
            ) ?? NSImage(),
            target: self,
            action: #selector(clearShortcut(_:))
        )
        clearButton.bezelStyle = .inline
        clearButton.isBordered = false
        clearButton.imagePosition = .imageOnly
        clearButton.contentTintColor = .tertiaryLabelColor
        clearButton.tag = actionIndex(action)
        clearButton.toolTip = L10n.format("Disable the shortcut for %@", action.localizedMenuTitle)
        clearButtons[action] = clearButton

        for view in [actionLabel, shortcutButton, clearButton] {
            view.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(view)
        }

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 42),
            actionLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            actionLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            actionLabel.trailingAnchor.constraint(lessThanOrEqualTo: shortcutButton.leadingAnchor, constant: -16),
            shortcutButton.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            shortcutButton.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -6),
            shortcutButton.widthAnchor.constraint(equalToConstant: 142),
            shortcutButton.heightAnchor.constraint(equalToConstant: 28),
            clearButton.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            clearButton.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 24),
            clearButton.heightAnchor.constraint(equalToConstant: 24)
        ])

        return row
    }

    private func buildFooter() -> NSView {
        let footer = NSView()

        let restoreButton = NSButton(
            title: L10n.text("Restore Defaults"),
            image: NSImage(systemSymbolName: "arrow.counterclockwise", accessibilityDescription: nil) ?? NSImage(),
            target: self,
            action: #selector(resetShortcuts)
        )
        restoreButton.bezelStyle = .rounded
        restoreButton.imagePosition = .imageLeading

        statusDot.wantsLayer = true
        statusDot.layer?.cornerRadius = 4
        statusDot.layer?.backgroundColor = NSColor.systemGreen.cgColor

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        let helpButton = NSButton(
            image: NSImage(
                systemSymbolName: "questionmark.circle",
                accessibilityDescription: L10n.text("Open PanePilot help")
            ) ?? NSImage(),
            target: self,
            action: #selector(openHelp)
        )
        helpButton.bezelStyle = .inline
        helpButton.isBordered = false
        helpButton.imagePosition = .imageOnly
        helpButton.toolTip = L10n.text("Open PanePilot help")

        for view in [restoreButton, statusDot, statusLabel, helpButton] {
            view.translatesAutoresizingMaskIntoConstraints = false
            footer.addSubview(view)
        }

        NSLayoutConstraint.activate([
            restoreButton.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 20),
            restoreButton.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
            statusDot.leadingAnchor.constraint(greaterThanOrEqualTo: restoreButton.trailingAnchor, constant: 16),
            statusDot.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 8),
            statusDot.heightAnchor.constraint(equalToConstant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 7),
            statusLabel.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: helpButton.leadingAnchor, constant: -12),
            helpButton.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -18),
            helpButton.centerYAnchor.constraint(equalTo: footer.centerYAnchor),
            helpButton.widthAnchor.constraint(equalToConstant: 24),
            helpButton.heightAnchor.constraint(equalToConstant: 24)
        ])

        return footer
    }

    private func separator() -> NSBox {
        let separator = NSBox()
        separator.boxType = .separator
        return separator
    }

    private func actionIndex(_ action: WindowAction) -> Int {
        WindowAction.menuOrder.firstIndex(of: action) ?? -1
    }

    private func action(for sender: NSButton) -> WindowAction? {
        guard sender.tag >= 0, sender.tag < WindowAction.menuOrder.count else { return nil }
        return WindowAction.menuOrder[sender.tag]
    }

    @objc private func beginRecording(_ sender: NSButton) {
        guard let action = action(for: sender) else { return }
        stopRecording(keepMessage: true)
        recordingAction = action
        onRecordingChanged(true)
        refreshRows()
        shortcutButtons[action]?.title = L10n.text("Type shortcut...")
        statusLabel.stringValue = L10n.format(
            "Recording %@. Press Escape to cancel.",
            action.localizedMenuTitle
        )
        statusDot.layer?.backgroundColor = NSColor.systemOrange.cgColor

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.capture(event)
            return nil
        }
    }

    @objc private func clearShortcut(_ sender: NSButton) {
        guard let action = action(for: sender) else { return }
        store.clear(action)
        applyShortcutChange(message: L10n.format("%@ is disabled.", action.localizedMenuTitle))
    }

    @objc private func resetShortcuts() {
        store.reset()
        applyShortcutChange(message: L10n.text("Default shortcuts restored."))
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSSwitch) {
        sender.isEnabled = false
        let presentation = loginItemController.setEnabled(sender.state == .on)
        applyLoginItemPresentation(presentation)
    }

    @objc private func openLoginItemsSettings() {
        loginItemController.openSystemSettings()
    }

    @objc private func openHelp() {
        guard let url = URL(string: L10n.text("PanePilot Help URL")) else { return }
        NSWorkspace.shared.open(url)
    }

    private func capture(_ event: NSEvent) {
        guard let action = recordingAction else { return }
        if event.keyCode == kVK_Escape && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
            stopRecording()
            return
        }
        guard let shortcut = KeyboardShortcut(action: action, event: event) else {
            NSSound.beep()
            statusLabel.stringValue = L10n.text("Use Command, Option, Control, or Shift in the shortcut.")
            stopRecording(keepMessage: true)
            statusDot.layer?.backgroundColor = NSColor.systemRed.cgColor
            return
        }
        if let conflict = WindowAction.menuOrder.first(where: { candidate in
            candidate != action
                && store.shortcut(for: candidate).map {
                    $0.keyCode == shortcut.keyCode && $0.modifiers == shortcut.modifiers
                } == true
        }) {
            NSSound.beep()
            statusLabel.stringValue = L10n.format(
                "%@ is already used by %@.",
                shortcut.symbolicLabel,
                conflict.localizedMenuTitle
            )
            stopRecording(keepMessage: true)
            statusDot.layer?.backgroundColor = NSColor.systemRed.cgColor
            return
        }
        store.set(shortcut, for: action)
        applyShortcutChange(
            message: L10n.format("%@ is now %@.", action.localizedMenuTitle, shortcut.symbolicLabel)
        )
    }

    private func applyShortcutChange(message: String) {
        stopRecording(keepMessage: true)
        statusLabel.stringValue = message
        refreshRows(preserveStatus: true)
        onShortcutsChanged()
    }

    private func stopRecording(keepMessage: Bool = false) {
        let wasRecording = recordingAction != nil
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
        recordingAction = nil
        if wasRecording {
            onRecordingChanged(false)
        }
        refreshRows(preserveStatus: keepMessage)
    }

    private func refreshRows(preserveStatus: Bool = false) {
        for action in WindowAction.menuOrder {
            let shortcut = store.shortcut(for: action)
            shortcutButtons[action]?.title = shortcut?.symbolicLabel ?? L10n.text("Set Shortcut")
            shortcutButtons[action]?.contentTintColor = shortcut == nil ? .secondaryLabelColor : .controlTextColor
            clearButtons[action]?.isEnabled = shortcut != nil
        }

        if !preserveStatus {
            let activeCount = store.resolvedShortcuts().count
            statusLabel.stringValue = activeCount == WindowAction.menuOrder.count
                ? L10n.text("All shortcuts are active")
                : L10n.format(
                    "%ld of %ld shortcuts active",
                    activeCount,
                    WindowAction.menuOrder.count
                )
        }
        statusDot.layer?.backgroundColor = recordingAction == nil
            ? NSColor.systemGreen.cgColor
            : NSColor.systemOrange.cgColor
    }

    private func refreshLoginItem() {
        applyLoginItemPresentation(loginItemController.refresh())
    }

    private func applyLoginItemPresentation(_ presentation: LoginItemPresentation) {
        launchAtLoginSwitch.state = presentation.isEnabled ? .on : .off
        launchAtLoginSwitch.isEnabled = true
        launchAtLoginDescription.stringValue = L10n.text(presentation.message)
        switch presentation.noticeStyle {
        case .info: launchAtLoginDescription.textColor = .systemOrange
        case .error: launchAtLoginDescription.textColor = .systemRed
        case nil: launchAtLoginDescription.textColor = .secondaryLabelColor
        }
        openLoginItemsButton.isHidden = !presentation.canOpenSystemSettings
    }
}

@MainActor
enum PreferencesSnapshotAutomation {
    static func run(path: String) -> Int32 {
        let app = NSApplication.shared
        switch ProcessInfo.processInfo.environment["PANEPILOT_SNAPSHOT_APPEARANCE"] {
        case "light": app.appearance = NSAppearance(named: .aqua)
        case "dark": app.appearance = NSAppearance(named: .darkAqua)
        default: break
        }
        app.setActivationPolicy(.regular)
        app.finishLaunching()

        let suiteName = "dev.panepilot.snapshot.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            print("PanePilot settings snapshot failed: could not create isolated preferences.")
            return 2
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let loginItemController = LoginItemController(service: SnapshotLoginItemService())
        let controller = PreferencesWindowController(
            store: ShortcutStore(defaults: defaults),
            loginItemController: loginItemController
        ) {}
        if ProcessInfo.processInfo.environment["PANEPILOT_SNAPSHOT_SIZE"] == "minimum" {
            controller.window?.setContentSize(NSSize(width: 620, height: 520))
        }
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        app.activate()
        RunLoop.main.run(until: Date().addingTimeInterval(0.35))

        let outputURL = URL(fileURLWithPath: path)
        guard controller.renderSnapshot(to: outputURL) else {
            print("PanePilot settings snapshot failed: could not render \(path).")
            return 3
        }
        print("PanePilot settings snapshot written to \(path)")
        return 0
    }
}

private struct SnapshotLoginItemService: LoginItemServicing {
    var status: SMAppService.Status {
        ProcessInfo.processInfo.environment["PANEPILOT_SNAPSHOT_LOGIN_ITEM"] == "approval"
            ? .requiresApproval
            : .notRegistered
    }
    func register() throws {}
    func unregister() throws {}
}
