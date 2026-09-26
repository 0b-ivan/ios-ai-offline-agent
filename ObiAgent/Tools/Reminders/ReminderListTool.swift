import Foundation
import FoundationModels

struct ReminderListTool: Tool {
    let name = "list_reminders"
    let description = """
    Reads the person's reminders.
    Use this when the person asks what tasks or reminders they have.
    """

    private let store: ReminderStore
    private let runtime: ToolRuntime

    @Generable
    struct Arguments {
        @Guide(description: "Set to true only when completed reminders are relevant to the request.")
        let includeCompleted: Bool
    }

    init(store: ReminderStore, runtime: ToolRuntime) {
        self.store = store
        self.runtime = runtime
    }

    func call(arguments: Arguments) async throws -> String {
        await runtime.record(
            toolName: name,
            risk: .read,
            status: .started,
            summary: arguments.includeCompleted
                ? "Read reminders including completed items."
                : "Read incomplete reminders."
        )

        do {
            let reminders = try await store.reminders(
                includeCompleted: arguments.includeCompleted
            )

            await runtime.record(
                toolName: name,
                risk: .read,
                status: .completed,
                summary: "Returned \(reminders.count) reminder(s)."
            )

            guard !reminders.isEmpty else {
                return "No matching reminders found."
            }

            return reminders.prefix(50).map { reminder in
                let due = reminder.dueDate?.formatted(
                    date: .abbreviated,
                    time: .omitted
                ) ?? "no due date"
                let state = reminder.isCompleted ? "completed" : "open"

                return "\(reminder.title) — \(due) — \(state) [\(reminder.calendarTitle)]"
            }
            .joined(separator: "\n")
        } catch {
            await runtime.record(
                toolName: name,
                risk: .read,
                status: .failed,
                summary: error.localizedDescription
            )
            throw error
        }
    }
}
