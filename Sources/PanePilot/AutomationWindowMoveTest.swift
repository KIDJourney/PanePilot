import AppKit
import Darwin
import PanePilotCore

@MainActor
enum AutomationHotKeyDispatchTest {
    static func run() -> Int32 {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()

        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.loginwindow" {
            print("PanePilot hotkey dispatch failed: active desktop is loginwindow. Unlock the Mac before running make verify-hotkey-dispatch.")
            return 10
        }
        guard let shortcut = HotKeyManager.defaultShortcuts.first(where: { $0.action == .leftHalf }) else {
            print("PanePilot hotkey dispatch failed: missing default Left Half shortcut.")
            return 4
        }

        let run = HotKeyDispatchRun(app: app, shortcut: shortcut)
        run.start()
        app.run()
        return 8
    }
}

@MainActor
enum AutomationHotKeyRecordingTest {
    static func run() -> Int32 {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()

        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.loginwindow" {
            print("PanePilot shortcut recording test failed: active desktop is loginwindow.")
            return 10
        }
        guard let shortcut = HotKeyManager.defaultShortcuts.first(where: { $0.action == .leftHalf }) else {
            print("PanePilot shortcut recording test failed: missing default Left Half shortcut.")
            return 4
        }

        let run = HotKeyRecordingRun(app: app, shortcut: shortcut)
        run.start()
        app.run()
        return 8
    }
}

@MainActor
enum AutomationWindowMoveTest {
    static func run() -> Int32 {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        app.finishLaunching()

        let client = AccessibilityWindowClient()
        guard client.isTrusted(prompt: false) else {
            print("PanePilot automation failed: Accessibility permission is not granted for this executable.")
            return 2
        }
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.loginwindow" {
            print("PanePilot automation failed: active desktop is loginwindow. Unlock the Mac and keep a user desktop active before running make verify-window-move.")
            return 10
        }

        let fixtureWindow = NSWindow(
            contentRect: NSRect(x: 220, y: 180, width: 720, height: 480),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        fixtureWindow.title = "PanePilot Automation Fixture"
        fixtureWindow.makeKeyAndOrderFront(nil)
        let activationDeadline = Date().addingTimeInterval(2)
        let testActivationOptions = NSApplication.ActivationOptions(rawValue: 3)
        while NSWorkspace.shared.frontmostApplication?.processIdentifier != getpid(),
              Date() < activationDeadline {
            NSRunningApplication.current.activate(options: testActivationOptions)
            fixtureWindow.makeKeyAndOrderFront(nil)
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        }

        guard NSWorkspace.shared.frontmostApplication?.processIdentifier == getpid() else {
            print("PanePilot automation failed: fixture app did not become frontmost.")
            return 11
        }
        guard let window = client.window(forProcessIdentifier: getpid()) else {
            print("PanePilot automation failed: fixture window was not available through Accessibility.")
            return 3
        }
        guard let activeID = client.activeDisplayID(for: window.rect),
              let target = LayoutEngine().targetRect(for: .leftHalf, window: window.rect, displays: client.displays(), activeDisplayID: activeID)
        else {
            print("PanePilot automation failed: could not compute expected Left Half target.")
            return 5
        }

        let run = WindowMoveRun(
            app: app,
            client: client,
            fixtureWindow: fixtureWindow,
            window: window,
            expected: target
        )
        run.start()
        app.run()
        return 8
    }
}

@MainActor
enum AutomationChromeTransitionTest {
    static func run(processIdentifier: pid_t) -> Int32 {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()

        let client = AccessibilityWindowClient()
        guard client.isTrusted(prompt: false) else {
            print("PanePilot Chrome transition failed: Accessibility permission is not granted for this executable.")
            return 2
        }
        guard let window = waitForWindow(processIdentifier: processIdentifier, client: client) else {
            print("PanePilot Chrome transition failed: Chrome test window was not available through Accessibility.")
            return 3
        }
        guard let displayID = client.activeDisplayID(for: window.rect) else {
            print("PanePilot Chrome transition failed: could not identify the Chrome window display.")
            return 4
        }

        let layoutEngine = LayoutEngine()
        let displays = client.displays()
        guard
            let maximized = layoutEngine.targetRect(for: .maximize, window: window.rect, displays: displays, activeDisplayID: displayID),
            let leftHalf = layoutEngine.targetRect(for: .leftHalf, window: window.rect, displays: displays, activeDisplayID: displayID),
            let rightHalf = layoutEngine.targetRect(for: .rightHalf, window: window.rect, displays: displays, activeDisplayID: displayID)
        else {
            print("PanePilot Chrome transition failed: could not compute target frames.")
            return 5
        }

        let originalRect = window.rect
        defer { _ = client.set(originalRect, for: window) }

        guard client.set(maximized, for: window), waitForRect(maximized, window: window, client: client) else {
            print("PanePilot Chrome transition failed: test window did not maximize.")
            return 6
        }
        guard client.set(rightHalf, for: window) else {
            print("PanePilot Chrome transition failed: Right Half AX writes failed.")
            return 7
        }

        var observedLeftHalf = false
        var observedFrames: [CGRect] = []
        let deadline = Date().addingTimeInterval(1)
        while Date() < deadline {
            if let rect = client.rect(for: window) {
                if observedFrames.last?.isApproximatelyEqual(to: rect, tolerance: 1) != true {
                    observedFrames.append(rect)
                }
                observedLeftHalf = observedLeftHalf || rect.isApproximatelyEqual(to: leftHalf, tolerance: 3)
                if rect.isApproximatelyEqual(to: rightHalf, tolerance: 3) {
                    break
                }
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }

        let frameSummary = observedFrames.map(\.debugDescription).joined(separator: " -> ")
        guard client.rect(for: window)?.isApproximatelyEqual(to: rightHalf, tolerance: 3) == true else {
            print("PanePilot Chrome transition failed: final frame was not Right Half. frames=\(frameSummary)")
            return 8
        }
        guard !observedLeftHalf else {
            print("PanePilot Chrome transition failed: window passed through Left Half. frames=\(frameSummary)")
            return 9
        }

        print("PanePilot Chrome transition passed: maximized window moved directly to Right Half. frames=\(frameSummary)")
        return 0
    }

    private static func waitForWindow(
        processIdentifier: pid_t,
        client: AccessibilityWindowClient
    ) -> ManagedWindow? {
        let deadline = Date().addingTimeInterval(8)
        repeat {
            if let window = client.window(forProcessIdentifier: processIdentifier) {
                return window
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline
        return nil
    }

    private static func waitForRect(
        _ expected: CGRect,
        window: ManagedWindow,
        client: AccessibilityWindowClient
    ) -> Bool {
        let deadline = Date().addingTimeInterval(2)
        repeat {
            if client.rect(for: window)?.isApproximatelyEqual(to: expected, tolerance: 3) == true {
                return true
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        } while Date() < deadline
        return false
    }
}

@MainActor
private final class HotKeyDispatchRun: NSObject {
    let app: NSApplication
    let shortcut: KeyboardShortcut
    let hotKeyManager = HotKeyManager()
    var timer: Timer?
    var receivedActions: [WindowAction] = []
    var startedAt = Date()

    init(app: NSApplication, shortcut: KeyboardShortcut) {
        self.app = app
        self.shortcut = shortcut
        super.init()
    }

    func start() {
        hotKeyManager.actionHandler = { [weak self] action in
            Task { @MainActor in
                self?.receivedActions.append(action)
            }
        }
        hotKeyManager.register(shortcuts: [shortcut])
        startedAt = Date()
        print("PanePilot hotkey dispatch ready: inject Option-Command-Left from an external process.")
        fflush(stdout)
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(tick(_:)), userInfo: nil, repeats: true)
    }

    @objc private func tick(_ timer: Timer) {
        if receivedActions.contains(.leftHalf) {
            finish(0, message: "PanePilot hotkey dispatch passed: Option-Command-Left reached HotKeyManager action handler.")
            return
        }
        if Date().timeIntervalSince(startedAt) > 5 {
            finish(6, message: "PanePilot hotkey dispatch failed: external shortcut was not delivered. actions=\(receivedActions.map(\.rawValue))")
        }
    }

    private func finish(_ code: Int32, message: String) {
        print(message)
        fflush(stdout)
        timer?.invalidate()
        exit(code)
    }
}

@MainActor
private final class HotKeyRecordingRun: NSObject {
    let app: NSApplication
    let shortcut: KeyboardShortcut
    let hotKeyManager = HotKeyManager()
    var timer: Timer?
    var receivedActions: [WindowAction] = []
    var startedAt = Date()
    var phase = 0

    init(app: NSApplication, shortcut: KeyboardShortcut) {
        self.app = app
        self.shortcut = shortcut
        super.init()
    }

    func start() {
        hotKeyManager.actionHandler = { [weak self] action in
            Task { @MainActor in
                self?.receivedActions.append(action)
            }
        }
        hotKeyManager.register(shortcuts: [shortcut])
        hotKeyManager.setSuspended(true)
        startedAt = Date()
        print("PanePilot shortcut recording suspended: inject Option-Command-Left.")
        fflush(stdout)
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(tick(_:)), userInfo: nil, repeats: true)
    }

    @objc private func tick(_ timer: Timer) {
        switch phase {
        case 0 where Date().timeIntervalSince(startedAt) >= 0.75:
            guard receivedActions.isEmpty else {
                finish(6, message: "PanePilot shortcut recording failed: a suspended global shortcut was delivered.")
                return
            }
            hotKeyManager.setSuspended(false)
            phase = 1
            startedAt = Date()
            print("PanePilot shortcut recording resumed: inject Option-Command-Left.")
            fflush(stdout)
        case 1 where receivedActions.contains(.leftHalf):
            finish(0, message: "PanePilot shortcut recording passed: suspended input was ignored and resumed input was delivered.")
        case 1 where Date().timeIntervalSince(startedAt) > 5:
            finish(7, message: "PanePilot shortcut recording failed: shortcut was not restored after recording.")
        default:
            break
        }
    }

    private func finish(_ code: Int32, message: String) {
        print(message)
        fflush(stdout)
        timer?.invalidate()
        exit(code)
    }
}

@MainActor
private final class WindowMoveRun: NSObject {
    let app: NSApplication
    let client: AccessibilityWindowClient
    let fixtureWindow: NSWindow
    let window: ManagedWindow
    let originalRect: CGRect
    let expected: CGRect
    let commander: WindowCommander
    var timer: Timer?
    var commandStartedAt: Date?

    init(
        app: NSApplication,
        client: AccessibilityWindowClient,
        fixtureWindow: NSWindow,
        window: ManagedWindow,
        expected: CGRect
    ) {
        self.app = app
        self.client = client
        self.fixtureWindow = fixtureWindow
        self.window = window
        self.originalRect = window.rect
        self.expected = expected
        self.commander = WindowCommander(windowClient: client)
        super.init()
    }

    func start() {
        print("PanePilot window move ready: execute Left Half against the frontmost fixture window.")
        fflush(stdout)
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(tick(_:)), userInfo: nil, repeats: true)
    }

    @objc private func tick(_ timer: Timer) {
        guard let commandStartedAt else {
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == getpid() else {
                finish(7, message: "PanePilot automation failed: fixture window lost focus before the command ran.")
                return
            }
            commander.perform(.leftHalf)
            self.commandStartedAt = Date()
            return
        }

        guard Date().timeIntervalSince(commandStartedAt) >= 0.25 else {
            return
        }
        let currentRect = client.rect(for: window)
        if currentRect?.isApproximatelyEqual(to: expected, tolerance: 3) == true {
            finish(0, message: "PanePilot automation passed: WindowCommander moved the fixture window to Left Half.")
        } else {
            let current = currentRect?.debugDescription ?? "nil"
            finish(6, message: "PanePilot automation failed: WindowCommander did not move the fixture window. expected=\(expected.debugDescription) actual=\(current)")
        }
    }

    private func finish(_ code: Int32, message: String) {
        if let currentRect = client.rect(for: window),
           !currentRect.isApproximatelyEqual(to: originalRect, tolerance: 1) {
            _ = client.set(originalRect, for: window)
        }
        print(message)
        fflush(stdout)
        timer?.invalidate()
        exit(code)
    }
}

private extension CGRect {
    func isApproximatelyEqual(to other: CGRect, tolerance: CGFloat) -> Bool {
        abs(minX - other.minX) <= tolerance
            && abs(minY - other.minY) <= tolerance
            && abs(width - other.width) <= tolerance
            && abs(height - other.height) <= tolerance
    }
}
