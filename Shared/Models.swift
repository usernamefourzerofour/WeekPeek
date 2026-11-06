import Foundation
import SwiftUI

struct RGB: Hashable, Codable {
    var r: Double, g: Double, b: Double

    var color: Color { Color(red: r, green: g, blue: b) }

    /// White or black text depending on the background brightness.
    var textColor: Color {
        (0.299 * r + 0.587 * g + 0.114 * b) > 0.7 ? .black : .white
    }
}

struct WidgetEvent: Hashable, Identifiable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let color: RGB
    var isDeclined: Bool = false
}

/// Widget size, independent of WidgetKit so the layout logic can be unit tested.
enum WidgetSize: String, CaseIterable, Hashable {
    case small, medium, large
    /// iPad only: as wide as two large widgets.
    case extraLarge

    /// Default number of days and columns when "Automatic layout" is on.
    var defaultGrid: (days: Int, columns: Int) {
        switch self {
        case .small: return (2, 2)
        case .medium: return (5, 5)
        case .large, .extraLarge: return (14, 7)
        }
    }

    /// Same limits for every size: in StandBy the small widget is scaled up, so dense layouts stay readable.
    /// Narrow columns fall back to shorter day headers (`DayLayout.HeaderStyle`).
    var maxDays: Int { 14 }
    var maxColumns: Int { 7 }
    var padding: CGFloat { self == .large || self == .extraLarge ? 12 : 10 }
}

struct GridSpec: Hashable {
    let days: Int
    let columns: Int
    var rows: Int { (days + columns - 1) / columns }
}

struct WeekSettings: Hashable {
    /// nil = automatic for the widget size.
    var dayCount: Int? = nil
    var columns: Int? = nil
    var startDay: StartDay = .today
    var lines: LinesOption = .auto
    var fontSize = 11
    var showStartTime = true
    var showWeekNumber = false
    var colorStyle: ColorStyle = .calendar
    var daysOffMode: DaysOffMode = .weekend
    /// Calendar weekday numbers (1 = Sunday … 7 = Saturday), used when daysOffMode == .custom.
    var daysOff: Set<Int> = []
    var allDayMode: AllDayMode = .show
    var hideFinished = false
    var hideDeclined = false
    var showEmptyDays = true
    var app: CalendarApp = .google
    /// nil or empty = all calendars (new calendars are included automatically).
    var calendarIDs: Set<String>? = nil

    static let fontRange = 8...20

    var clampedFontSize: CGFloat { CGFloat(min(Self.fontRange.upperBound, max(Self.fontRange.lowerBound, fontSize))) }

    func grid(for size: WidgetSize) -> GridSpec {
        let days = min(size.maxDays, max(1, dayCount ?? size.defaultGrid.days))
        let cols = min(size.maxColumns, max(1, min(columns ?? size.defaultGrid.columns, days)))
        return GridSpec(days: days, columns: cols)
    }
}

struct WeekModel: Hashable {
    var now: Date
    var settings: WeekSettings
    var events: [WidgetEvent]
    var hasAccess: Bool
}

extension WeekModel {
    static func sample(now: Date, settings: WeekSettings = WeekSettings(), calendar: Calendar = .current) -> WeekModel {
        let today = calendar.startOfDay(for: now)
        func at(_ day: Int, _ hour: Int, _ minutes: Int = 60) -> (Date, Date) {
            let s = calendar.date(byAdding: .hour, value: hour, to: calendar.date(byAdding: .day, value: day, to: today)!)!
            return (s, s.addingTimeInterval(TimeInterval(minutes * 60)))
        }
        func allDay(_ day: Int) -> (Date, Date) {
            let s = calendar.date(byAdding: .day, value: day, to: today)!
            return (s, calendar.date(byAdding: .day, value: 1, to: s)!.addingTimeInterval(-1))
        }
        let blue = RGB(r: 0.55, g: 0.58, b: 0.92)
        let red = RGB(r: 0.93, g: 0.36, b: 0.27)
        let green = RGB(r: 0.30, g: 0.70, b: 0.45)
        let items: [(String, (Date, Date), Bool, RGB)] = [
            ("Check oil", allDay(0), true, blue),
            ("Football practice", at(0, 17), false, red),
            ("School drop-off", at(1, 8), false, red),
            ("Wedding anniversary", allDay(1), true, blue),
            ("Swimming", at(1, 16), false, green),
            ("Talk at the public library about local history", at(2, 19, 90), false, red),
            ("School drop-off", at(2, 8), false, red),
            ("Dentist", at(3, 10), false, green),
            ("Concert", at(4, 20, 120), false, red),
            ("School drop-off", at(4, 8), false, red),
            ("Meeting", at(4, 9), false, green),
            ("Lunch", at(4, 12), false, green),
            ("Groceries", at(4, 15), false, green),
            ("Training", at(4, 17), false, red),
            ("Dinner club", at(4, 18), false, blue),
            ("Homework", at(4, 19), false, green),
            ("Birthday party at Grandma's", at(6, 14, 180), false, blue),
            ("Car service", at(8, 9), false, green),
            ("Parent-teacher meeting", at(9, 17), false, red),
            ("Holiday", allDay(11), true, blue),
        ]
        let events = items.enumerated().map { i, item in
            WidgetEvent(id: "sample-\(i)", title: item.0, start: item.1.0, end: item.1.1, isAllDay: item.2, color: item.3)
        }
        return WeekModel(now: now, settings: settings, events: events, hasAccess: true)
    }
}
