import Foundation

public enum WindowAction: String, CaseIterable, Sendable {
    case center
    case maximize
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case upperLeft
    case lowerLeft
    case upperRight
    case lowerRight
    case nextThird
    case previousThird
    case larger
    case smaller
    case nextDisplay
    case previousDisplay
    case undo
    case redo

    public var menuTitle: String {
        switch self {
        case .center: "Center"
        case .maximize: "Maximize"
        case .leftHalf: "Left Half"
        case .rightHalf: "Right Half"
        case .topHalf: "Top Half"
        case .bottomHalf: "Bottom Half"
        case .upperLeft: "Upper Left"
        case .lowerLeft: "Lower Left"
        case .upperRight: "Upper Right"
        case .lowerRight: "Lower Right"
        case .nextThird: "Next Third"
        case .previousThird: "Previous Third"
        case .larger: "Make Larger"
        case .smaller: "Make Smaller"
        case .nextDisplay: "Next Display"
        case .previousDisplay: "Previous Display"
        case .undo: "Undo"
        case .redo: "Redo"
        }
    }
}
