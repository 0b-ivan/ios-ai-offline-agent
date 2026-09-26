import XCTest
@testable import ObiAgent

@MainActor
final class ToolRuntimeTests: XCTestCase {
    func testReadRiskDoesNotRequireConfirmation() {
        XCTAssertFalse(ToolRisk.read.requiresConfirmation)
    }

    func testMutatingRisksRequireConfirmation() {
        XCTAssertTrue(ToolRisk.write.requiresConfirmation)
        XCTAssertTrue(ToolRisk.destructive.requiresConfirmation)
        XCTAssertTrue(ToolRisk.externalCommunication.requiresConfirmation)
    }

    func testDeniedWriteResumesPendingApprovalAsFalse() async {
        let runtime = ToolRuntime()

        let approvalTask = Task {
            await runtime.requestApproval(
                toolName: "test_write",
                risk: .write,
                summary: "Write something."
            )
        }

        await Task.yield()

        XCTAssertEqual(runtime.pendingApproval?.toolName, "test_write")
        XCTAssertEqual(runtime.pendingApproval?.risk, .write)

        runtime.resolvePendingApproval(approved: false)

        let approved = await approvalTask.value
        XCTAssertFalse(approved)
        XCTAssertNil(runtime.pendingApproval)
        XCTAssertEqual(runtime.activities.first?.status, .denied)
    }

    func testReadApprovalReturnsImmediately() async {
        let runtime = ToolRuntime()

        let approved = await runtime.requestApproval(
            toolName: "test_read",
            risk: .read,
            summary: "Read something."
        )

        XCTAssertTrue(approved)
        XCTAssertNil(runtime.pendingApproval)
    }
}
