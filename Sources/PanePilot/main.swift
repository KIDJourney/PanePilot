import AppKit

if CommandLine.arguments.contains("--automation-hotkey-test") {
    exit(AutomationWindowMoveTest.run())
}

if CommandLine.arguments.contains("--automation-hotkey-dispatch-test") {
    exit(AutomationHotKeyDispatchTest.run())
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
