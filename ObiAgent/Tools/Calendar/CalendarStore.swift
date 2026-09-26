import EventKit
import Foundation

struct CalendarEventSummary: Sendable {
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarTitle: String
}

actor CalendarStore {
    enum StoreError: LocalizedError {
        case accessDenied
        case invalidDateRange

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Calendar access was not granted."
            case .invalidDateRange:
                return "The requested calendar date range is invalid."
            }
        }
    }

    private let eventStore = EKEventStore()

    func events(on day: Date) async throws -> [CalendarEventSummary] {
        let hasAccess = try await ensureCalendarAccess()
        guard hasAccess else {
            throw StoreError.accessDenied
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: day)

        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            throw StoreError.invalidDateRange
        }

        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        return eventStore
            .events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .map { event in
                CalendarEventSummary(
                    title: event.title ?? "Untitled event",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    isAllDay: event.isAllDay,
                    calendarTitle: event.calendar.title
                )
            }
    }

    private func ensureCalendarAccess() async throws -> Bool {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:
            return true
        case .notDetermined:
            return try await eventStore.requestFullAccessToEvents()
        default:
            return false
        }
    }
}
