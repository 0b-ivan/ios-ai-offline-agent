import XCTest
@testable import ObiAgent

final class ToolPolicyTests: XCTestCase {
    func testReadToolsDoNotRequireConfirmation() {
        XCTAssertFalse(ToolRisk.read.requiresConfirmation)
    }

    func testMutatingAndExternalToolsRequireConfirmation() {
        XCTAssertTrue(ToolRisk.write.requiresConfirmation)
        XCTAssertTrue(ToolRisk.destructive.requiresConfirmation)
        XCTAssertTrue(ToolRisk.externalCommunication.requiresConfirmation)
    }

    func testCalendarDateParserHandlesTomorrowDeterministically() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let now = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 9, day: 27, hour: 12))
        )
        let expected = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 9, day: 28))
        )

        XCTAssertEqual(
            CalendarDateParser.parse(
                "morgen",
                relativeTo: now,
                calendar: calendar
            ),
            expected
        )
    }

    func testCalendarDateParserAcceptsISODate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let expected = try XCTUnwrap(
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 3))
        )

        XCTAssertEqual(
            CalendarDateParser.parse(
                "2026-10-03",
                relativeTo: expected,
                calendar: calendar
            ),
            expected
        )
    }
}
