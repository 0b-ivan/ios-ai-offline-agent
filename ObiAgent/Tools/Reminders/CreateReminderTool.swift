import Foundation
import FoundationModels

struct CreateReminderTool: Tool {
    let name = "create_reminder"
    let description = """
    Creates a reminder after the person explicitly approves the action.
    Use this only when the person asks to create or add a reminder.
    """

    private let store: ReminderStore
    private let runtime: ToolRuntime

    @Generable
    struct Arguments {
        @Guide(description: "Short reminder title.")
        let title: String

        @Guide(description: "Optional due date in yyyy-MM-dd format.")
        let dueDate: String?
    }

    init(store: ReminderStore, runtime: ToolRuntime) {
        self.store = store
        self.runtime = runtime
    }

    func call(arguments: Arguments) async throws -> String {
        let title = arguments.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            return "A reminder title is required."
        }

        let dueDate: Date?
        if let rawDate = arguments.dueDate, !rawDate.isEmpty {
            guard let parsedDate = CalendarDateParser.parse(rawDate) else {
                return "The reminder due date '\(rawDate)' is invalid. Use yyyy-MM-dd."
            }
            dueDate = parsedDate
        } else {
            dueDate = nil
        }

        let dueLabel = dueDate?.formatted(
            date: .abbreviated,
            time: .omitted
        ) ?? "without a due date"

        let approvalSummary = "Create reminder “\(title)” \(dueLabel)."

        let approved = await runtime.requestApproval(
            toolName: name,
            risk: .write,
            summary: approvalSummary
        )

        guard approved else {
            return "The person did not approve creating the reminder."
        }

        do {
            let reminder = try await store.create(
                title: title,
                dueDate: dueDate
            )

            await runtime.record(
                toolName: name,
                risk: .write,
                status: .completed,
                summary: "Created reminder “\(reminder.title)” in \(reminder.calendarTitle)."
            )

            return "Created reminder “\(reminder.title)” \(dueLabel) in \(reminder.calendarTitle)."
        } catch {
            await runtime.record(
                toolName: name,
                risk: .write,
                status: .failed,
                summary: error.localizedDescription
            )
            throw error
        }
    }
}
