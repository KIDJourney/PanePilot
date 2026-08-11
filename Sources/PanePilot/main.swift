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

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
