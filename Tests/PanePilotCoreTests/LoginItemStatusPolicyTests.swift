import Testing
@testable import PanePilotCore

struct LoginItemStatusPolicyTests {
    @Test
    func onlyEnabledStatusAppearsEnabled() {
        #expect(LoginItemStatusPolicy.presentation(for: .enabled).isEnabled)
        #expect(!LoginItemStatusPolicy.presentation(for: .notRegistered).isEnabled)
        #expect(!LoginItemStatusPolicy.presentation(for: .requiresApproval).isEnabled)
        #expect(!LoginItemStatusPolicy.presentation(for: .notFound).isEnabled)
    }

    @Test
    func approvalStatusLinksToSystemSettings() {
        let presentation = LoginItemStatusPolicy.presentation(for: .requiresApproval)

        #expect(presentation.noticeStyle == .info)
        #expect(presentation.canOpenSystemSettings)
        #expect(presentation.message == "Approval is required in System Settings.")
    }

    @Test
    func missingRegistrationAppearsAsDisabledUntilTheUserEnablesIt() {
        let presentation = LoginItemStatusPolicy.presentation(for: .notFound)

        #expect(presentation.noticeStyle == nil)
        #expect(!presentation.canOpenSystemSettings)
        #expect(presentation.message == "Open PanePilot automatically when you log in.")
    }

    @Test
    func updateFailurePreservesTheRealEnabledState() {
        #expect(LoginItemStatusPolicy.updateFailed(isEnabled: true).isEnabled)
        #expect(!LoginItemStatusPolicy.updateFailed(isEnabled: false).isEnabled)
    }
}
