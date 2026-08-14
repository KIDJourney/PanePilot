public enum WindowFrameAttribute: Equatable, Sendable {
    case size
    case position
}

public enum WindowFrameWritePlan {
    public static let constrainedApplicationOrder: [WindowFrameAttribute] = [
        .size,
        .position,
        .size
    ]
}
