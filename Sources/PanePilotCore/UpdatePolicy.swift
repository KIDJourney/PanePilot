import Foundation

public struct AppVersion: Comparable, Equatable, Sendable {
    public let components: [Int]

    public init?(_ value: String) {
        let normalized = value.hasPrefix("v") ? String(value.dropFirst()) : value
        let core = normalized.split(separator: "-", maxSplits: 1).first.map(String.init) ?? normalized
        let parts = core.split(separator: ".", omittingEmptySubsequences: false)
        guard !parts.isEmpty, parts.allSatisfy({ Int($0) != nil }) else { return nil }
        components = parts.map { Int($0)! }
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        return false
    }

    public static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }
}

public enum UpdateSchedule {
    public static func nextCheckDate(
        after now: Date,
        lastCheckDate: Date?,
        calendar: Calendar = .current
    ) -> Date {
        let todayNoon = calendar.date(
            bySettingHour: 12,
            minute: 0,
            second: 0,
            of: now
        ) ?? now

        if now < todayNoon {
            return todayNoon
        }

        if lastCheckDate == nil || lastCheckDate! < todayNoon {
            return now.addingTimeInterval(2)
        }

        return calendar.date(byAdding: .day, value: 1, to: todayNoon) ?? now.addingTimeInterval(86_400)
    }
}
