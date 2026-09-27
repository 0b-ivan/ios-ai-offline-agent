import Combine
import Foundation
import FoundationModels

@MainActor
final class AgentViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var input = ""
    @Published var isResponding = false

    private let model: SystemLanguageModel
    private let session: LanguageModelSession
    private let toolRuntime: ToolRuntime
    private var cancellables = Set<AnyCancellable>()

    init(
        calendarStore: CalendarStore = CalendarStore(),
        reminderStore: ReminderStore = ReminderStore(),
        contactStore: ContactStore = ContactStore(),
        toolRuntime: ToolRuntime = ToolRuntime()
    ) {
        let model = SystemLanguageModel.default

        let tools: [any Tool] = [
            CalendarTool(store: calendarStore, runtime: toolRuntime),
            ReminderListTool(store: reminderStore, runtime: toolRuntime),
            CreateReminderTool(store: reminderStore, runtime: toolRuntime),
            ContactLookupTool(store: contactStore, runtime: toolRuntime)
        ]

        self.model = model
        self.toolRuntime = toolRuntime
        self.session = LanguageModelSession(
            model: model,
            tools: tools,
            instructions: """
            You are Obi, a private personal assistant running on an iPhone.
            Respond in the same language as the person.
            Be concise and factual.
            Use available tools whenever the answer depends on current or private device data.
            Never invent calendar events, reminders, contacts, or successful actions.
            Calendar and reminder dates passed to tools should use yyyy-MM-dd.
            Write actions are independently gated by the app and may be denied by the person.
            Today is \(Date.now.formatted(date: .complete, time: .omitted)).
            """
        )

        toolRuntime.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var isModelAvailable: Bool {
        model.isAvailable
    }

    var pendingApproval: ToolApprovalRequest? {
        toolRuntime.pendingApproval
    }

    var toolActivities: [ToolActivity] {
        toolRuntime.activities
    }

    var canSend: Bool {
        isModelAvailable
            && !isResponding
            && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var modelStatus: String {
        switch model.availability {
        case .available:
            return "On-device model bereit"
        case .unavailable(.deviceNotEligible):
            return "Dieses Gerät unterstützt das Systemmodell nicht"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Apple Intelligence ist deaktiviert"
        case .unavailable(.modelNotReady):
            return "On-device model ist noch nicht bereit"
        @unknown default:
            return "On-device model ist nicht verfügbar"
        }
    }

    func resolvePendingApproval(approved: Bool) {
        toolRuntime.resolvePendingApproval(approved: approved)
    }

    func send() async {
        guard !isResponding else { return }

        let prompt = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        messages.append(ChatMessage(role: .user, text: prompt))
        input = ""

        guard model.isAvailable else {
            messages.append(
                ChatMessage(
                    role: .assistant,
                    text: "Das lokale Apple-Foundation-Model ist auf diesem Gerät momentan nicht verfügbar."
                )
            )
            return
        }

        isResponding = true
        defer { isResponding = false }

        do {
            let response = try await session.respond(to: prompt)
            messages.append(ChatMessage(role: .assistant, text: response.content))
        } catch {
            messages.append(
                ChatMessage(
                    role: .assistant,
                    text: "Die Anfrage konnte nicht lokal verarbeitet werden: \(error.localizedDescription)"
                )
            )
        }
    }
}
