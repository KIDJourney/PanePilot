import AppKit
import PanePilotCore

@MainActor
final class PreferencesWindowController: NSWindowController, NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate {
    private let store: ShortcutStore
    private let onShortcutsChanged: () -> Void
    private let actions = WindowAction.menuOrder
    private let tableView = NSTableView()
    private let recordButton = NSButton(title: "Record", target: nil, action: nil)
    private let clearButton = NSButton(title: "Clear", target: nil, action: nil)
    private let resetButton = NSButton(title: "Reset Defaults", target: nil, action: nil)
    private let doneButton = NSButton(title: "Done", target: nil, action: nil)
    private let statusLabel = NSTextField(labelWithString: "")
    private var eventMonitor: Any?
    private var recordingAction: WindowAction?

    init(store: ShortcutStore, onShortcutsChanged: @escaping () -> Void) {
        self.store = store
        self.onShortcutsChanged = onShortcutsChanged

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "PanePilot Shortcuts"
        window.center()
        super.init(window: window)
        window.delegate = self
        window.contentView = buildContentView()
        updateSelectionState()
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

    func numberOfRows(in tableView: NSTableView) -> Int {
        actions.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < actions.count, let identifier = tableColumn?.identifier else {
            return nil
        }
        let action = actions[row]
        let text: String
        if identifier.rawValue == "action" {
            text = action.menuTitle
        } else {
            text = store.shortcut(for: action)?.label ?? "Disabled"
        }

        let cell = NSTableCellView()
        let label = NSTextField(labelWithString: text)
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateSelectionState()
    }

    private func buildContentView() -> NSView {
        let contentView = NSView()
        let titleLabel = NSTextField(labelWithString: "Keyboard Shortcuts")
        titleLabel.font = .preferredFont(forTextStyle: .title2)

        let subtitleLabel = NSTextField(labelWithString: "Select an action, record a shortcut, or clear one you do not use.")
        subtitleLabel.textColor = .secondaryLabelColor

        tableView.headerView = nil
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = false
        tableView.rowHeight = 32
        let actionColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("action"))
        actionColumn.title = "Action"
        actionColumn.width = 250
        let shortcutColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("shortcut"))
        shortcutColumn.title = "Shortcut"
        shortcutColumn.width = 300
        tableView.addTableColumn(actionColumn)
        tableView.addTableColumn(shortcutColumn)

        let scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        for button in [recordButton, clearButton, resetButton, doneButton] {
            button.bezelStyle = .rounded
            button.translatesAutoresizingMaskIntoConstraints = false
        }
        recordButton.target = self
        recordButton.action = #selector(recordSelectedShortcut)
        clearButton.target = self
        clearButton.action = #selector(clearSelectedShortcut)
        resetButton.target = self
        resetButton.action = #selector(resetShortcuts)
        doneButton.target = self
        doneButton.action = #selector(done)

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        let buttonStack = NSStackView(views: [recordButton, clearButton, resetButton, NSView(), doneButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8
        buttonStack.distribution = .fill

        let stack = NSStackView(views: [titleLabel, subtitleLabel, scrollView, statusLabel, buttonStack])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            scrollView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 340),
            statusLabel.widthAnchor.constraint(equalTo: stack.widthAnchor),
            buttonStack.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])

        return contentView
    }

    @objc private func recordSelectedShortcut() {
        guard let action = selectedAction else { return }
        recordingAction = action
        statusLabel.stringValue = "Press a new shortcut for \(action.menuTitle). Use at least one modifier."
        recordButton.title = "Press Shortcut..."
        recordButton.isEnabled = false
        clearButton.isEnabled = false
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.capture(event)
            return nil
        }
    }

    @objc private func clearSelectedShortcut() {
        guard let action = selectedAction else { return }
        store.clear(action)
        applyShortcutChange(message: "\(action.menuTitle) disabled.")
    }

    @objc private func resetShortcuts() {
        store.reset()
        applyShortcutChange(message: "Default shortcuts restored.")
    }

    @objc private func done() {
        close()
    }

    private func capture(_ event: NSEvent) {
        guard let action = recordingAction else { return }
        guard let shortcut = KeyboardShortcut(action: action, event: event) else {
            NSSound.beep()
            statusLabel.stringValue = "Shortcut must include Command, Option, Control, or Shift."
            stopRecording(keepMessage: true)
            return
        }
        if let conflict = actions.first(where: { candidate in
            candidate != action && store.shortcut(for: candidate).map { $0.keyCode == shortcut.keyCode && $0.modifiers == shortcut.modifiers } == true
        }) {
            NSSound.beep()
            statusLabel.stringValue = "\(shortcut.label) is already used by \(conflict.menuTitle)."
            stopRecording(keepMessage: true)
            return
        }
        store.set(shortcut, for: action)
        applyShortcutChange(message: "\(action.menuTitle) set to \(shortcut.label).")
    }

    private func applyShortcutChange(message: String) {
        stopRecording(keepMessage: true)
        statusLabel.stringValue = message
        tableView.reloadData()
        updateSelectionState()
        onShortcutsChanged()
    }

    private func stopRecording(keepMessage: Bool = false) {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
        recordingAction = nil
        recordButton.title = "Record"
        if !keepMessage {
            statusLabel.stringValue = ""
        }
        updateSelectionState()
    }

    private func updateSelectionState() {
        let hasSelection = selectedAction != nil && recordingAction == nil
        recordButton.isEnabled = hasSelection
        clearButton.isEnabled = hasSelection
    }

    private var selectedAction: WindowAction? {
        let row = tableView.selectedRow
        guard row >= 0, row < actions.count else {
            return nil
        }
        return actions[row]
    }
}
