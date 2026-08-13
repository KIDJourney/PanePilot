import CoreGraphics
import Testing
@testable import PanePilotCore

struct LayoutEngineTests {
    private let engine = LayoutEngine()
    private let display = DisplayFrame(id: "main", visibleFrame: CGRect(x: 0, y: 24, width: 1440, height: 876))

    @Test func leftHalfUsesVisibleFrame() {
        let target = engine.targetRect(
            for: .leftHalf,
            window: CGRect(x: 200, y: 200, width: 600, height: 400),
            displays: [display],
            activeDisplayID: "main"
        )

        #expect(target?.equalTo(CGRect(x: 0, y: 24, width: 720, height: 876)) == true)
    }

    @Test func centerPreservesWindowSize() {
        let target = engine.targetRect(
            for: .center,
            window: CGRect(x: 0, y: 0, width: 600, height: 300),
            displays: [display],
            activeDisplayID: "main"
        )

        #expect(target?.equalTo(CGRect(x: 420, y: 312, width: 600, height: 300)) == true)
    }

    @Test func nextDisplayPreservesRelativePosition() {
        let second = DisplayFrame(id: "side", visibleFrame: CGRect(x: 1440, y: 0, width: 1000, height: 800))
        let target = engine.targetRect(
            for: .nextDisplay,
            window: CGRect(x: 360, y: 243, width: 720, height: 438),
            displays: [display, second],
            activeDisplayID: "main"
        )

        #expect(target?.equalTo(CGRect(x: 1690, y: 200, width: 500, height: 400)) == true)
    }

    @Test func leftHalfUsesTheDisplayWithTheLargestWindowOverlap() {
        let wideExternalAbove = DisplayFrame(
            id: "external",
            visibleFrame: CGRect(x: 0, y: -1416, width: 2560, height: 1416)
        )
        let primary = DisplayFrame(
            id: "primary",
            visibleFrame: CGRect(x: 0, y: 24, width: 1440, height: 876)
        )

        let target = engine.targetRect(
            for: .leftHalf,
            window: CGRect(x: 300, y: 200, width: 800, height: 500),
            displays: [wideExternalAbove, primary],
            activeDisplayID: nil
        )

        #expect(target?.equalTo(CGRect(x: 0, y: 24, width: 720, height: 876)) == true)
    }

    @Test func cocoaFramesUseThePrimaryScreenTopAsTheAccessibilityOrigin() {
        let primaryFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let externalVisibleFrame = CGRect(x: 0, y: 900, width: 2560, height: 1416)

        let converted = DisplayGeometry.accessibilityFrame(
            fromCocoaFrame: externalVisibleFrame,
            primaryScreenFrame: primaryFrame
        )

        #expect(converted.equalTo(CGRect(x: 0, y: -1416, width: 2560, height: 1416)))
    }
}
