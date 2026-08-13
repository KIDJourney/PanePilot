import AppKit

if CommandLine.arguments.contains("--automation-hotkey-test") {
    exit(AutomationWindowMoveTest.run())
}

if CommandLine.arguments.contains("--automation-hotkey-dispatch-test") {
    exit(AutomationHotKeyDispatchTest.run())
}

if let snapshotFlag = CommandLine.arguments.firstIndex(of: "--automation-preferences-snapshot"),
   CommandLine.arguments.indices.contains(snapshotFlag + 1) {
    exit(PreferencesSnapshotAutomation.run(path: CommandLine.arguments[snapshotFlag + 1]))
}

if let loginItemFlag = CommandLine.arguments.firstIndex(of: "--automation-login-item-test") {
    let resultPath = CommandLine.arguments.indices.contains(loginItemFlag + 1)
        ? CommandLine.arguments[loginItemFlag + 1]
        : nil
    exit(LoginItemAutomation.run(resultPath: resultPath))
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
