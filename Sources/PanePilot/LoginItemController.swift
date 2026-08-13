import AppKit
import PanePilotCore
import ServiceManagement

protocol LoginItemServicing {
    var status: SMAppService.Status { get }
    func register() throws
    func unregister() throws
}

struct MainAppLoginItemService: LoginItemServicing {
    var status: SMAppService.Status {
        SMAppService.mainApp.status
    }

    func register() throws {
        try SMAppService.mainApp.register()
    }

    func unregister() throws {
        try SMAppService.mainApp.unregister()
    }
}

@MainActor
final class LoginItemController {
    private let service: LoginItemServicing
    private(set) var presentation: LoginItemPresentation

    init(service: LoginItemServicing = MainAppLoginItemService()) {
        self.service = service
        self.presentation = LoginItemStatusPolicy.presentation(for: service.status.registrationStatus)
    }

    @discardableResult
    func refresh() -> LoginItemPresentation {
        presentation = LoginItemStatusPolicy.presentation(for: service.status.registrationStatus)
        return presentation
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) -> LoginItemPresentation {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            return refresh()
        } catch {
            let current = refresh()
            if current.canOpenSystemSettings {
                return current
            }
            presentation = LoginItemStatusPolicy.updateFailed(isEnabled: current.isEnabled)
            return presentation
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

private extension SMAppService.Status {
    var registrationStatus: LoginItemRegistrationStatus {
        switch self {
        case .notRegistered: .notRegistered
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notFound: .notFound
        @unknown default: .unknown
        }
    }
}

@MainActor
enum LoginItemAutomation {
    static func run(resultPath: String?) -> Int32 {
        guard Bundle.main.bundleIdentifier == "dev.panepilot.login-item-test" else {
            return finish(10, "PanePilot login item test refused: use the isolated test bundle identifier.", at: resultPath)
        }

        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.finishLaunching()

        let service = SMAppService.mainApp
        do {
            if service.status == .enabled || service.status == .requiresApproval {
                try service.unregister()
            }
            guard service.status == .notRegistered || service.status == .notFound else {
                return finish(2, "PanePilot login item test failed: setup status is \(service.status.rawValue).", at: resultPath)
            }

            try service.register()
            let registeredStatus = service.status
            guard registeredStatus == .enabled || registeredStatus == .requiresApproval else {
                try? service.unregister()
                return finish(3, "PanePilot login item test failed: register status is \(registeredStatus.rawValue).", at: resultPath)
            }

            try service.unregister()
            guard service.status == .notRegistered else {
                return finish(4, "PanePilot login item test failed: cleanup status is \(service.status.rawValue).", at: resultPath)
            }

            return finish(0, "PanePilot login item test passed: register=\(registeredStatus.rawValue), unregister=\(service.status.rawValue).", at: resultPath)
        } catch {
            try? service.unregister()
            return finish(5, "PanePilot login item test failed: \(error.localizedDescription)", at: resultPath)
        }
    }

    private static func finish(_ code: Int32, _ message: String, at path: String?) -> Int32 {
        print(message)
        if let path {
            try? "\(code)\n\(message)\n".write(toFile: path, atomically: true, encoding: .utf8)
        }
        return code
    }
}
