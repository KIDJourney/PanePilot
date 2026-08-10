import AppKit
import PanePilotCore

@MainActor
final class WindowCommander {
    private let windowClient: AccessibilityWindowClient
    private let layoutEngine: LayoutEngine
    private var undoStack: [HistoryItem] = []
    private var redoStack: [HistoryItem] = []

    init(windowClient: AccessibilityWindowClient, layoutEngine: LayoutEngine = LayoutEngine()) {
        self.windowClient = windowClient
        self.layoutEngine = layoutEngine
    }

    @discardableResult
    func requestAccessibilityPermission(prompt: Bool) -> Bool {
        let trusted = windowClient.isTrusted(prompt: prompt)
        if !trusted, prompt {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
        return trusted
    }

    func perform(_ action: WindowAction) {
        guard requestAccessibilityPermission(prompt: true) else {
            NSSound.beep()
            return
        }

        switch action {
        case .undo:
            restore(from: &undoStack, pushingTo: &redoStack)
        case .redo:
            restore(from: &redoStack, pushingTo: &undoStack)
        default:
            moveFocusedWindow(action)
        }
    }

    private func moveFocusedWindow(_ action: WindowAction) {
        guard let window = windowClient.focusedWindow() else {
            NSSound.beep()
            return
        }
        let displays = windowClient.displays()
        let activeID = windowClient.activeDisplayID(for: window.rect)
        guard let target = layoutEngine.targetRect(for: action, window: window.rect, displays: displays, activeDisplayID: activeID) else {
            return
        }
        guard target.integral != window.rect.integral else {
            return
        }
        if windowClient.set(target, for: window) {
            undoStack.append(HistoryItem(window: window, rect: window.rect))
            redoStack.removeAll()
        } else {
            NSSound.beep()
        }
    }

    private func restore(from source: inout [HistoryItem], pushingTo destination: inout [HistoryItem]) {
        guard let item = source.popLast() else {
            NSSound.beep()
            return
        }
        guard let currentRect = windowClient.rect(for: item.window) else {
            NSSound.beep()
            return
        }
        let current = ManagedWindow(element: item.window.element, rect: currentRect)
        if windowClient.set(item.rect, for: item.window) {
            destination.append(HistoryItem(window: current, rect: currentRect))
        } else {
            NSSound.beep()
        }
    }
}

private struct HistoryItem {
    var window: ManagedWindow
    var rect: CGRect
}
