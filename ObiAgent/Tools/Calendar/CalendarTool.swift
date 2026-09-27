import Foundation
import FoundationModels

struct CalendarTool: Tool {
    let name = "calendar_events"
    let description: String

    private let store: CalendarStore
    private let runtime: ToolRuntime

    @Generable
    struct Arguments {
        @Guide(description: "Calendar day to read in yyyy-MM-dd format.")
        let date: String
    }

    init(
        store: CalendarStore,
        runtime: ToolRuntime,
        now: Date = .now
    ) {
        self.store = store
        self.runtime = runtime
        self.description = """
        Reads the person's calendar events for one day.
        Use this whenever a question depends on their calendar.
        Today is \(now.formatted(date: .complete, time: .omitted)).
        """
    }

    func call(arguments: Arguments) async throws -> String {
        guard let day = CalendarDateParser.parse(arguments.date) else {
            return "The calendar date '\(arguments.date)' is invalid. Use yyyy-MM-dd."
        }

        let dayLabel = day.formatted(date: .complete, time: .omitted)

        await runtime.record(
            toolName: name,
            risk: .read,
            status: .started,
            summary: "Read calendar events for \(dayLabel)."
        )

        do {
            let events = try await store.events(on: day)

            await runtime.record(
                toolName: name,
                risk: .read,
                status: .completed,
                summary: "Returned \(events.count) calendar event(s) for \(dayLabel)."
            )

            guard !events.isEmpty else {
                return "No calendar events found for \(dayLabel)."
            }

            return events.map { event in
                if event.isAllDay {
                    return "All day — \(event.title) [\(event.calendarTitle)]"
                }

                let start = event.startDate.formatted(
                    date: .omitted,
                    time: .shortened
                )
                let end = event.endDate.formatted(
                    date: .omitted,
                    time: .shortened
                )

                return "\(start)–\(end) — \(event.title) [\(event.calendarTitle)]"
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
