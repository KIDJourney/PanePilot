import AppKit
import PanePilotCore

struct ShortcutStore {
    private static let key = "shortcutOverrides.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func resolvedShortcuts() -> [KeyboardShortcut] {
        let overrides = loadOverrides()
        return HotKeyManager.defaultShortcuts.compactMap { defaultShortcut in
            guard let override = overrides[defaultShortcut.action.rawValue] else {
                return defaultShortcut
            }
            guard let keyCode = override.keyCode else {
                return nil
            }
            return KeyboardShortcut(action: defaultShortcut.action, keyCode: keyCode, modifiers: Set(override.modifiers))
        }
    }

    func shortcut(for action: WindowAction) -> KeyboardShortcut? {
        resolvedShortcuts().first { $0.action == action }
    }

    func set(_ shortcut: KeyboardShortcut, for action: WindowAction) {
        var overrides = loadOverrides()
        overrides[action.rawValue] = ShortcutOverride(keyCode: shortcut.keyCode, modifiers: Array(shortcut.modifiers))
        save(overrides)
    }

    func clear(_ action: WindowAction) {
        var overrides = loadOverrides()
        overrides[action.rawValue] = ShortcutOverride(keyCode: nil, modifiers: [])
        save(overrides)
    }

    func reset() {
        defaults.removeObject(forKey: Self.key)
    }

    private func loadOverrides() -> [String: ShortcutOverride] {
        guard let data = defaults.data(forKey: Self.key) else {
            return [:]
        }
        return (try? JSONDecoder().decode([String: ShortcutOverride].self, from: data)) ?? [:]
    }

    private func save(_ overrides: [String: ShortcutOverride]) {
        if let data = try? JSONEncoder().encode(overrides) {
            defaults.set(data, forKey: Self.key)
        }
    }
}

private struct ShortcutOverride: Codable {
    var keyCode: Int?
    var modifiers: [KeyboardModifier]
}

extension KeyboardShortcut {
    init?(action: WindowAction, event: NSEvent) {
        let modifiers = KeyboardModifier.from(event.modifierFlags)
        guard !modifiers.isEmpty else {
            return nil
        }
        self.init(action: action, keyCode: Int(event.keyCode), modifiers: modifiers)
    }
}

private extension KeyboardModifier {
    static func from(_ flags: NSEvent.ModifierFlags) -> Set<KeyboardModifier> {
        var modifiers: Set<KeyboardModifier> = []
        if flags.contains(.command) {
            modifiers.insert(.command)
        }
        if flags.contains(.control) {
            modifiers.insert(.control)
        }
        if flags.contains(.option) {
            modifiers.insert(.option)
        }
        if flags.contains(.shift) {
            modifiers.insert(.shift)
        }
        return modifiers
    }
}
