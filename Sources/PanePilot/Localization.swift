import Foundation
import PanePilotCore

enum L10n {
    private static let bundle: Bundle = {
        guard
            let language = ProcessInfo.processInfo.environment["PANEPILOT_TEST_LANGUAGE"],
            let path = Bundle.main.path(forResource: language, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return .main
        }
        return bundle
    }()

    static func text(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale.current, arguments: arguments)
    }
}

extension WindowAction {
    var localizedMenuTitle: String {
        L10n.text(menuTitle)
    }
}

enum LocalizationAutomation {
    static func run() -> Int32 {
        print([
            L10n.text("PanePilot Settings"),
            WindowAction.center.localizedMenuTitle,
            L10n.text("Check for Updates..."),
            L10n.text("Open PanePilot automatically when you log in."),
            L10n.text("Install Update"),
            L10n.text("PanePilot Could Not Update"),
            L10n.format("Recording %@. Press Escape to cancel.", WindowAction.rightHalf.localizedMenuTitle),
            L10n.format("%ld of %ld shortcuts active", 3, 18)
        ].joined(separator: "|"))
        return 0
    }
}
