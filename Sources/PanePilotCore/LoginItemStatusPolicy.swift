public enum LoginItemRegistrationStatus: Equatable, Sendable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
    case unknown
}

public enum LoginItemNoticeStyle: Equatable, Sendable {
    case info
    case error
}

public struct LoginItemPresentation: Equatable, Sendable {
    public var isEnabled: Bool
    public var message: String
    public var noticeStyle: LoginItemNoticeStyle?
    public var canOpenSystemSettings: Bool

    public init(
        isEnabled: Bool,
        message: String,
        noticeStyle: LoginItemNoticeStyle? = nil,
        canOpenSystemSettings: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.message = message
        self.noticeStyle = noticeStyle
        self.canOpenSystemSettings = canOpenSystemSettings
    }
}

public enum LoginItemStatusPolicy {
    public static func presentation(for status: LoginItemRegistrationStatus) -> LoginItemPresentation {
        switch status {
        case .enabled:
            LoginItemPresentation(
                isEnabled: true,
                message: "PanePilot opens automatically when you log in."
            )
        case .notRegistered:
            LoginItemPresentation(
                isEnabled: false,
                message: "Open PanePilot automatically when you log in."
            )
        case .requiresApproval:
            LoginItemPresentation(
                isEnabled: false,
                message: "Approval is required in System Settings.",
                noticeStyle: .info,
                canOpenSystemSettings: true
            )
        case .notFound:
            LoginItemPresentation(
                isEnabled: false,
                message: "Open PanePilot automatically when you log in."
            )
        case .unknown:
            LoginItemPresentation(
                isEnabled: false,
                message: "Launch at Login status is temporarily unavailable.",
                noticeStyle: .error
            )
        }
    }

    public static func updateFailed(isEnabled: Bool) -> LoginItemPresentation {
        LoginItemPresentation(
            isEnabled: isEnabled,
            message: "Could not update Launch at Login. Try again.",
            noticeStyle: .error
        )
    }
}
