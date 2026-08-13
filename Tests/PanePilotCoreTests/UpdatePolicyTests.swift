import Foundation
import Testing
@testable import PanePilotCore

struct UpdatePolicyTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func versionsCompareNumerically() {
        #expect(AppVersion("v0.1.10")! > AppVersion("0.1.9")!)
        #expect(AppVersion("1.0")! == AppVersion("1.0.0")!)
        #expect(AppVersion("v2.0.0-beta")! > AppVersion("1.9.9")!)
    }

    @Test func checkWaitsUntilNoonWhenLaunchedInTheMorning() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 8, day: 13, hour: 9))!
        let expected = calendar.date(from: DateComponents(year: 2026, month: 8, day: 13, hour: 12))!

        #expect(UpdateSchedule.nextCheckDate(after: now, lastCheckDate: nil, calendar: calendar) == expected)
    }

    @Test func checkRunsAfterLaunchWhenNoonWasMissed() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 8, day: 13, hour: 15))!

        #expect(UpdateSchedule.nextCheckDate(after: now, lastCheckDate: nil, calendar: calendar) == now.addingTimeInterval(2))
    }

    @Test func onlyOneAutomaticCheckRunsAfterNoonEachDay() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 8, day: 13, hour: 15))!
        let lastCheck = calendar.date(from: DateComponents(year: 2026, month: 8, day: 13, hour: 12, minute: 1))!
        let expected = calendar.date(from: DateComponents(year: 2026, month: 8, day: 14, hour: 12))!

        #expect(UpdateSchedule.nextCheckDate(after: now, lastCheckDate: lastCheck, calendar: calendar) == expected)
    }
}
