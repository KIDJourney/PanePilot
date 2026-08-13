import CoreGraphics

public enum DisplayGeometry {
    public static func accessibilityFrame(
        fromCocoaFrame frame: CGRect,
        primaryScreenFrame: CGRect
    ) -> CGRect {
        CGRect(
            x: frame.minX,
            y: primaryScreenFrame.maxY - frame.maxY,
            width: frame.width,
            height: frame.height
        )
    }

    public static func activeDisplay(in displays: [DisplayFrame], for window: CGRect) -> DisplayFrame? {
        guard var bestDisplay = displays.first else { return nil }

        var bestIntersectionArea = intersectionArea(window, bestDisplay.visibleFrame)
        for display in displays.dropFirst() {
            let area = intersectionArea(window, display.visibleFrame)
            if area > bestIntersectionArea {
                bestDisplay = display
                bestIntersectionArea = area
            }
        }
        if bestIntersectionArea > 0 {
            return bestDisplay
        }

        let center = CGPoint(x: window.midX, y: window.midY)
        return displays.min {
            squaredDistance(from: center, to: $0.visibleFrame) < squaredDistance(from: center, to: $1.visibleFrame)
        }
    }

    private static func intersectionArea(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull, !intersection.isEmpty else { return 0 }
        return intersection.width * intersection.height
    }

    private static func squaredDistance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(rect.minX - point.x, 0, point.x - rect.maxX)
        let dy = max(rect.minY - point.y, 0, point.y - rect.maxY)
        return dx * dx + dy * dy
    }
}
