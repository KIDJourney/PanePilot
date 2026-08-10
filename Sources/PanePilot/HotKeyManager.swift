import AppKit
import Carbon
import PanePilotCore

final class HotKeyManager {
    var actionHandler: ((WindowAction) -> Void)?

    private var hotKeyRefs: [UInt32: EventHotKeyRef?] = [:]
    private var actions: [UInt32: WindowAction] = [:]
    private var nextID: UInt32 = 1
    private var eventHandler: EventHandlerRef?

    deinit {
        for ref in hotKeyRefs.values {
            if let ref {
                UnregisterEventHotKey(ref)
            }
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    func registerDefaults() {
        installEventHandlerIfNeeded()
        for shortcut in Self.defaultShortcuts {
            register(shortcut)
        }
    }

    func handleHotKey(id: UInt32) {
        guard let action = actions[id] else { return }
        actionHandler?(action)
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyCallback,
            1,
            &eventType,
            userData,
            &eventHandler
        )
    }

    private func register(_ shortcut: KeyboardShortcut) {
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: nextID)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr else {
            NSLog("PanePilot could not register hotkey for \(shortcut.action.rawValue): \(status)")
            return
        }
        actions[nextID] = shortcut.action
        hotKeyRefs[nextID] = ref
        nextID += 1
    }

    static func shortcutLabel(for action: WindowAction) -> String? {
        defaultShortcuts.first(where: { $0.action == action })?.label
    }

    private static let signature = OSType(
        UInt32(UInt8(ascii: "P")) << 24
            | UInt32(UInt8(ascii: "P")) << 16
            | UInt32(UInt8(ascii: "L")) << 8
            | UInt32(UInt8(ascii: "T"))
    )

    private static let defaultShortcuts: [KeyboardShortcut] = [
        .init(action: .center, keyCode: kVK_ANSI_C, modifiers: [.command, .option], label: "Option-Command-C"),
        .init(action: .maximize, keyCode: kVK_ANSI_F, modifiers: [.command, .option], label: "Option-Command-F"),
        .init(action: .leftHalf, keyCode: kVK_LeftArrow, modifiers: [.command, .option], label: "Option-Command-Left"),
        .init(action: .rightHalf, keyCode: kVK_RightArrow, modifiers: [.command, .option], label: "Option-Command-Right"),
        .init(action: .topHalf, keyCode: kVK_UpArrow, modifiers: [.command, .option], label: "Option-Command-Up"),
        .init(action: .bottomHalf, keyCode: kVK_DownArrow, modifiers: [.command, .option], label: "Option-Command-Down"),
        .init(action: .upperLeft, keyCode: kVK_LeftArrow, modifiers: [.control, .command], label: "Control-Command-Left"),
        .init(action: .lowerLeft, keyCode: kVK_LeftArrow, modifiers: [.control, .shift, .command], label: "Control-Shift-Command-Left"),
        .init(action: .upperRight, keyCode: kVK_RightArrow, modifiers: [.control, .command], label: "Control-Command-Right"),
        .init(action: .lowerRight, keyCode: kVK_RightArrow, modifiers: [.control, .shift, .command], label: "Control-Shift-Command-Right"),
        .init(action: .nextDisplay, keyCode: kVK_RightArrow, modifiers: [.control, .option, .command], label: "Control-Option-Command-Right"),
        .init(action: .previousDisplay, keyCode: kVK_LeftArrow, modifiers: [.control, .option, .command], label: "Control-Option-Command-Left"),
        .init(action: .nextThird, keyCode: kVK_RightArrow, modifiers: [.control, .option], label: "Control-Option-Right"),
        .init(action: .previousThird, keyCode: kVK_LeftArrow, modifiers: [.control, .option], label: "Control-Option-Left"),
        .init(action: .larger, keyCode: kVK_RightArrow, modifiers: [.control, .option, .shift], label: "Control-Option-Shift-Right"),
        .init(action: .smaller, keyCode: kVK_LeftArrow, modifiers: [.control, .option, .shift], label: "Control-Option-Shift-Left"),
        .init(action: .undo, keyCode: kVK_ANSI_Z, modifiers: [.command, .option], label: "Option-Command-Z"),
        .init(action: .redo, keyCode: kVK_ANSI_Z, modifiers: [.command, .option, .shift], label: "Option-Shift-Command-Z")
    ]
}

private let hotKeyCallback: EventHandlerUPP = { _, event, userData in
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return status }
    let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
    manager.handleHotKey(id: hotKeyID.id)
    return noErr
}

private struct KeyboardShortcut {
    var action: WindowAction
    var keyCode: Int
    var modifiers: Set<KeyboardModifier>
    var label: String

    var carbonModifiers: UInt32 {
        modifiers.reduce(UInt32(0)) { $0 | $1.carbonValue }
    }
}

private enum KeyboardModifier {
    case command
    case control
    case option
    case shift

    var carbonValue: UInt32 {
        switch self {
        case .command: UInt32(cmdKey)
        case .control: UInt32(controlKey)
        case .option: UInt32(optionKey)
        case .shift: UInt32(shiftKey)
        }
    }
}
