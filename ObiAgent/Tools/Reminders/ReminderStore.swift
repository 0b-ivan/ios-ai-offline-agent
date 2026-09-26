import EventKit
import Foundation

struct ReminderSummary: Sendable {
    let title: String
    let dueDate: Date?
    let isCompleted: Bool
    let calendarTitle: String
}

actor ReminderStore {
    enum StoreError: LocalizedError {
        case accessDenied
        case noWritableReminderList

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Reminders access was not granted."
            case .noWritableReminderList:
                return "No writable reminder list is available."
            }
        }
    }

    private let eventStore = EKEventStore()

    func reminders(includeCompleted: Bool) async throws -> [ReminderSummary] {
        guard try await ensureAccess() else {
            throw StoreError.accessDenied
        }

        let predicate: NSPredicate
        if includeCompleted {
            predicate = eventStore.predicateForReminders(in: nil)
        } else {
            predicate = eventStore.predicateForIncompleteReminders(
                withDueDateStarting: nil,
                ending: nil,
                calendars: nil
            )
        }

        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                let summaries = (reminders ?? [])
                    .map { reminder in
                        ReminderSummary(
                            title: reminder.title,
                            dueDate: reminder.dueDateComponents.flatMap {
                                Calendar.current.date(from: $0)
                            },
                            isCompleted: reminder.isCompleted,
                            calendarTitle: reminder.calendar.title
                        )
                    }
                    .sorted { lhs, rhs in
                        switch (lhs.dueDate, rhs.dueDate) {
                        case let (left?, right?):
                            return left < right
                        case (.some, .none):
                            return true
                        case (.none, .some):
                            return false
                        case (.none, .none):
                            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                        }
                    }

                continuation.resume(returning: summaries)
            }
        }
    }

    func create(title: String, dueDate: Date?) async throws -> ReminderSummary {
        guard try await ensureAccess() else {
            throw StoreError.accessDenied
        }

        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            throw StoreError.noWritableReminderList
        }

        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = calendar

        if let dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day],
                from: dueDate
            )
        }

        try eventStore.save(reminder, commit: true)

        return ReminderSummary(
            title: reminder.title,
            dueDate: dueDate,
            isCompleted: reminder.isCompleted,
            calendarTitle: calendar.title
        )
    }

    private func ensureAccess() async throws -> Bool {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .fullAccess:
            return true
        case .notDetermined:
            return try await eventStore.requestFullAccessToReminders()
        default:
            return false
        }
    }
}
