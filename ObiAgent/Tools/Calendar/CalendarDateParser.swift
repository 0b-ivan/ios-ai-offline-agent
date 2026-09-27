import Foundation

enum CalendarDateParser {
    static func parse(
        _ value: String,
        relativeTo now: Date = .now,
        calendar: Calendar = .current
    ) -> Date? {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalized {
        case "today", "heute":
            return calendar.startOfDay(for: now)
        case "tomorrow", "morgen":
            return calendar.date(
                byAdding: .day,
                value: 1,
                to: calendar.startOfDay(for: now)
            )
        default:
            break
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter.date(from: normalized)
    }
}
