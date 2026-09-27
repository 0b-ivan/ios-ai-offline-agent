import Combine
import Foundation

enum ToolRisk: String, Sendable {
    case read
    case write
    case destructive
    case externalCommunication

    var requiresConfirmation: Bool {
        self != .read
    }
}

enum ToolActivityStatus: String, Sendable {
    case started
    case waitingForApproval
    case approved
    case denied
    case completed
    case failed
}

struct ToolActivity: Identifiable, Sendable {
    let id: UUID
    let toolName: String
    let risk: ToolRisk
    let status: ToolActivityStatus
    let summary: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        toolName: String,
        risk: ToolRisk,
        status: ToolActivityStatus,
        summary: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.toolName = toolName
        self.risk = risk
        self.status = status
        self.summary = summary
        self.createdAt = createdAt
    }
}

struct ToolApprovalRequest: Identifiable, Sendable {
    let id: UUID
    let toolName: String
    let risk: ToolRisk
    let summary: String

    init(
        id: UUID = UUID(),
        toolName: String,
        risk: ToolRisk,
        summary: String
    ) {
        self.id = id
        self.toolName = toolName
        self.risk = risk
        self.summary = summary
    }
}

@MainActor
final class ToolRuntime: ObservableObject, @unchecked Sendable {
    @Published private(set) var pendingApproval: ToolApprovalRequest?
    @Published private(set) var activities: [ToolActivity] = []

    private var approvalContinuation: CheckedContinuation<Bool, Never>?

    func record(
        toolName: String,
        risk: ToolRisk,
        status: ToolActivityStatus,
        summary: String
    ) {
        activities.insert(
            ToolActivity(
                toolName: toolName,
                risk: risk,
                status: status,
                summary: summary
            ),
            at: 0
        )

        if activities.count > 50 {
            activities.removeLast(activities.count - 50)
        }
    }

    func requestApproval(
        toolName: String,
        risk: ToolRisk,
        summary: String
    ) async -> Bool {
        guard risk.requiresConfirmation else {
            return true
        }

        guard approvalContinuation == nil else {
            record(
                toolName: toolName,
                risk: risk,
                status: .denied,
                summary: "Another tool action is already waiting for approval."
            )
            return false
        }

        record(
            toolName: toolName,
            risk: risk,
            status: .waitingForApproval,
            summary: summary
        )

        let request = ToolApprovalRequest(
            toolName: toolName,
            risk: risk,
            summary: summary
        )

        return await withCheckedContinuation { continuation in
            pendingApproval = request
            approvalContinuation = continuation
        }
    }

    func resolvePendingApproval(approved: Bool) {
        guard
            let request = pendingApproval,
            let continuation = approvalContinuation
        else {
            return
        }

        pendingApproval = nil
        approvalContinuation = nil

        record(
            toolName: request.toolName,
            risk: request.risk,
            status: approved ? .approved : .denied,
            summary: request.summary
        )

        continuation.resume(returning: approved)
    }
}
