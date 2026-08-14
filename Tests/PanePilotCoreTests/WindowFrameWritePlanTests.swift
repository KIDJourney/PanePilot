import Testing
@testable import PanePilotCore

struct WindowFrameWritePlanTests {
    @Test func constrainedApplicationsResizeBeforeAndAfterMoving() {
        #expect(
            WindowFrameWritePlan.constrainedApplicationOrder == [
                .size,
                .position,
                .size
            ]
        )
    }
}
