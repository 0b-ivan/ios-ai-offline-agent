import XCTest
@testable import ObiAgent

final class CalendarDateParserTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testParsesISODate() throws {
        let parsed = try XCTUnwrap(
            CalendarDateParser.parse(
                "2026-09-27",
                calendar: calendar
            )
        )

        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: parsed
        )

        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 9)
        XCTAssertEqual(components.day, 27)
    }

    func testParsesGermanTomorrowRelativeToReferenceDate() throws {
        let reference = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 9,
                    day: 26,
                    hour: 18
                )
            )
        )

        let parsed = try XCTUnwrap(
            CalendarDateParser.parse(
                "morgen",
                relativeTo: reference,
                calendar: calendar
            )
        )

        let expected = try XCTUnwrap(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 9,
                    day: 27
                )
            )
        )

        XCTAssertEqual(parsed, expected)
    }

    func testRejectsInvalidDate() {
        XCTAssertNil(
            CalendarDateParser.parse(
                "not-a-date",
                calendar: calendar
            )
        )
    }
}
