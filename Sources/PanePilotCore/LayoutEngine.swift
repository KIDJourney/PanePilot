import CoreGraphics
import Foundation

public struct DisplayFrame: Equatable, Sendable {
    public var id: String
    public var visibleFrame: CGRect

    public init(id: String, visibleFrame: CGRect) {
        self.id = id
        self.visibleFrame = visibleFrame
    }

    public static func == (lhs: DisplayFrame, rhs: DisplayFrame) -> Bool {
        lhs.id == rhs.id && lhs.visibleFrame.equalTo(rhs.visibleFrame)
    }
}

public struct LayoutEngine: Sendable {
    public init() {}

    public func targetRect(
        for action: WindowAction,
        window: CGRect,
        displays: [DisplayFrame],
        activeDisplayID: String?
    ) -> CGRect? {
        guard !displays.isEmpty else { return nil }
        let display = activeDisplay(in: displays, id: activeDisplayID, window: window)
        let frame = display.visibleFrame

        switch action {
        case .center:
            return centered(window: window, in: frame)
        case .maximize:
            return frame
        case .leftHalf:
            return CGRect(x: frame.minX, y: frame.minY, width: frame.width / 2, height: frame.height)
        case .rightHalf:
            return CGRect(x: frame.midX, y: frame.minY, width: frame.width / 2, height: frame.height)
        case .topHalf:
            return CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height / 2)
        case .bottomHalf:
            return CGRect(x: frame.minX, y: frame.midY, width: frame.width, height: frame.height / 2)
        case .upperLeft:
            return CGRect(x: frame.minX, y: frame.minY, width: frame.width / 2, height: frame.height / 2)
        case .lowerLeft:
            return CGRect(x: frame.minX, y: frame.midY, width: frame.width / 2, height: frame.height / 2)
        case .upperRight:
            return CGRect(x: frame.midX, y: frame.minY, width: frame.width / 2, height: frame.height / 2)
        case .lowerRight:
            return CGRect(x: frame.midX, y: frame.midY, width: frame.width / 2, height: frame.height / 2)
        case .nextThird:
            return third(after: window, in: frame, direction: 1)
        case .previousThird:
            return third(after: window, in: frame, direction: -1)
        case .larger:
            return scaled(window: window, in: frame, delta: 0.10)
        case .smaller:
            return scaled(window: window, in: frame, delta: -0.10)
        case .nextDisplay:
            return moved(window: window, from: display, in: displays, direction: 1)
        case .previousDisplay:
            return moved(window: window, from: display, in: displays, direction: -1)
        case .undo, .redo:
            return nil
        }
    }

    public func activeDisplay(in displays: [DisplayFrame], id: String?, window: CGRect) -> DisplayFrame {
        if let id, let display = displays.first(where: { $0.id == id }) {
            return display
        }
        let center = CGPoint(x: window.midX, y: window.midY)
        return displays.first(where: { $0.visibleFrame.contains(center) }) ?? displays[0]
    }

    private func centered(window: CGRect, in frame: CGRect) -> CGRect {
        let size = CGSize(width: min(window.width, frame.width), height: min(window.height, frame.height))
        return CGRect(
            x: frame.minX + (frame.width - size.width) / 2,
            y: frame.minY + (frame.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    private func third(after window: CGRect, in frame: CGRect, direction: Int) -> CGRect {
        let thirdWidth = frame.width / 3
        let currentIndex = Int(round((window.minX - frame.minX) / thirdWidth)).clamped(to: 0...2)
        let nextIndex = (currentIndex + direction + 3) % 3
        return CGRect(
            x: frame.minX + CGFloat(nextIndex) * thirdWidth,
            y: frame.minY,
            width: thirdWidth,
            height: frame.height
        )
    }

    private func scaled(window: CGRect, in frame: CGRect, delta: CGFloat) -> CGRect {
        let width = (window.width + frame.width * delta).clamped(to: min(160, frame.width)...frame.width)
        let height = (window.height + frame.height * delta).clamped(to: min(120, frame.height)...frame.height)
        let rect = CGRect(
            x: window.midX - width / 2,
            y: window.midY - height / 2,
            width: width,
            height: height
        )
        return rect.clamped(to: frame)
    }

    private func moved(window: CGRect, from display: DisplayFrame, in displays: [DisplayFrame], direction: Int) -> CGRect {
        guard displays.count > 1, let currentIndex = displays.firstIndex(of: display) else {
            return window.clamped(to: display.visibleFrame)
        }
        let nextIndex = (currentIndex + direction + displays.count) % displays.count
        let source = display.visibleFrame
        let target = displays[nextIndex].visibleFrame
        let relativeX = source.width == 0 ? 0 : (window.minX - source.minX) / source.width
        let relativeY = source.height == 0 ? 0 : (window.minY - source.minY) / source.height
        let relativeWidth = source.width == 0 ? 1 : window.width / source.width
        let relativeHeight = source.height == 0 ? 1 : window.height / source.height
        let rect = CGRect(
            x: target.minX + relativeX * target.width,
            y: target.minY + relativeY * target.height,
            width: min(target.width, relativeWidth * target.width),
            height: min(target.height, relativeHeight * target.height)
        )
        return rect.clamped(to: target)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private extension CGRect {
    func clamped(to bounds: CGRect) -> CGRect {
        let width = min(size.width, bounds.width)
        let height = min(size.height, bounds.height)
        return CGRect(
            x: min(max(origin.x, bounds.minX), bounds.maxX - width),
            y: min(max(origin.y, bounds.minY), bounds.maxY - height),
            width: width,
            height: height
        )
    }
}
