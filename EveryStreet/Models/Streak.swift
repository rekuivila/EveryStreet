import Foundation

struct StreakInfo {
    let current: Int
    let best: Int
    let lastWalkDate: Date?
}

enum StreakCalculator {
    static func compute(from walks: [Walk]) -> StreakInfo {
        guard !walks.isEmpty else {
            return StreakInfo(current: 0, best: 0, lastWalkDate: nil)
        }

        let calendar = Calendar.current
        let walkDays = Set(walks.map { calendar.startOfDay(for: $0.date) })
            .sorted(by: >)

        guard let mostRecent = walkDays.first else {
            return StreakInfo(current: 0, best: 0, lastWalkDate: nil)
        }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        guard mostRecent == today || mostRecent == yesterday else {
            return StreakInfo(
                current: 0,
                best: longestRun(in: walkDays),
                lastWalkDate: mostRecent
            )
        }

        var current = 1
        var prev = mostRecent
        for day in walkDays.dropFirst() {
            let expected = calendar.date(byAdding: .day, value: -1, to: prev)!
            if day == expected {
                current += 1
                prev = day
            } else {
                break
            }
        }

        return StreakInfo(
            current: current,
            best: max(current, longestRun(in: walkDays)),
            lastWalkDate: mostRecent
        )
    }

    private static func longestRun(in sortedDays: [Date]) -> Int {
        guard !sortedDays.isEmpty else { return 0 }
        let calendar = Calendar.current
        var best = 1
        var run = 1
        var prev = sortedDays[0]

        for day in sortedDays.dropFirst() {
            let expected = calendar.date(byAdding: .day, value: -1, to: prev)!
            if day == expected {
                run += 1
                best = max(best, run)
            } else {
                run = 1
            }
            prev = day
        }
        return best
    }
}
