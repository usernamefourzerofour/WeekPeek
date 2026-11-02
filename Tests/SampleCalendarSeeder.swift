import XCTest
import EventKit
import UIKit
@testable import KalenderWidget

/// Fills the Simulator's calendar with the sample events, for App Store screenshots of a real Home Screen.
/// Skipped unless run with `TEST_RUNNER_SEED_SAMPLE_EVENTS=1`; grant calendar access with `simctl privacy` first.
final class SampleCalendarSeeder: XCTestCase {
    func testSeedSampleCalendar() async throws {
        guard ProcessInfo.processInfo.environment["SEED_SAMPLE_EVENTS"] == "1" else {
            throw XCTSkip("Only when seeding screenshots")
        }
        let store = EKEventStore()
        let granted = try await store.requestFullAccessToEvents()
        try XCTSkipUnless(granted, "No calendar access")

        let source = try XCTUnwrap(store.sources.first { $0.sourceType == .local } ?? store.defaultCalendarForNewEvents?.source)
        let names = ["Work", "Family", "Kids"]   // green, blue, red (sorted by red component)
        for cal in store.calendars(for: .event) where names.contains(cal.title) {
            try store.removeCalendar(cal, commit: false)
        }
        func calendar(_ title: String, _ rgb: RGB) throws -> EKCalendar {
            let cal = EKCalendar(for: .event, eventStore: store)
            cal.title = title
            cal.source = source
            cal.cgColor = UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1).cgColor
            try store.saveCalendar(cal, commit: false)
            return cal
        }
        let sample = WeekModel.sample(now: Date())
        var calendars: [RGB: EKCalendar] = [:]
        for (rgb, name) in zip(Array(Set(sample.events.map(\.color))).sorted { $0.r < $1.r }, names) {
            calendars[rgb] = try calendar(name, rgb)
        }
        for e in sample.events {
            let event = EKEvent(eventStore: store)
            event.title = e.title
            event.startDate = e.start
            event.endDate = e.end
            event.isAllDay = e.isAllDay
            event.calendar = calendars[e.color]
            try store.save(event, span: .thisEvent, commit: false)
        }
        try store.commit()
    }
}
