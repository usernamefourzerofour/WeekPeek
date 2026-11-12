import Foundation
import AppIntents
import EventKit
import WidgetKit

struct CalendarEntity: AppEntity, Identifiable {
    let id: String
    let title: String
    let sourceTitle: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Calendar"
    static let defaultQuery = CalendarQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(sourceTitle)")
    }
}

struct CalendarQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CalendarEntity] {
        all().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [CalendarEntity] { all() }

    private func all() -> [CalendarEntity] {
        guard EventLoader.hasAccess else { return [] }
        return EKEventStore().calendars(for: .event)
            .map { CalendarEntity(id: $0.calendarIdentifier, title: $0.title, sourceTitle: $0.source?.title ?? "") }
            .sorted { ($0.sourceTitle, $0.title) < ($1.sourceTitle, $1.title) }
    }
}

/// Per-widget settings ("Edit Widget").
struct WeekWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "WeekPeek"
    static let description = IntentDescription("Choose days, layout, calendars and which app opens.")

    // First in Edit Widget: which app a tap opens is easy to miss further down.
    // Apple Calendar is always installed; the others may not be.
    @Parameter(title: "Open in", default: .apple)
    var app: CalendarApp

    @Parameter(title: "Number of days", default: .auto)
    var dayCount: DayCountOption

    @Parameter(title: "Columns", default: .auto)
    var columns: ColumnsOption

    @Parameter(title: "Start day", default: .today)
    var startDay: StartDay

    @Parameter(title: "Lines per event", default: .auto)
    var lines: LinesOption

    // A stepper (– and +) instead of a number field: with a field, iOS let people type a value
    // outside the range and then rejected the whole configuration (redacted placeholder).
    // WeekSettings.clampedFontSize still clamps to 6–20 as a safety net.
    @Parameter(title: "Text size (pt)", default: 11, controlStyle: .stepper, inclusiveRange: (6, 20))
    var fontSize: Int

    @Parameter(title: "Show start time", default: true)
    var showStartTime: Bool

    @Parameter(title: "Show week number", default: false)
    var showWeekNumber: Bool

    @Parameter(title: "Colors", default: .calendar)
    var colorStyle: ColorStyle

    @Parameter(title: "Days off", default: .weekend)
    var daysOffMode: DaysOffMode

    @Parameter(title: "Chosen days off")
    var daysOff: [WeekdayOption]?

    @Parameter(title: "All-day events", default: .show)
    var allDayMode: AllDayMode

    @Parameter(title: "Hide finished events", default: false)
    var hideFinished: Bool

    @Parameter(title: "Hide declined events", default: false)
    var hideDeclined: Bool

    @Parameter(title: "Mark empty days", default: true)
    var showEmptyDays: Bool

    @Parameter(title: "All calendars", default: true)
    var allCalendars: Bool

    @Parameter(title: "Calendars")
    var calendars: [CalendarEntity]?

    static var parameterSummary: some ParameterSummary {
        When(\.$allCalendars, .equalTo, true) {
            Summary {
                \.$app; \.$dayCount; \.$columns; \.$startDay; \.$lines; \.$fontSize; \.$showStartTime
                \.$showWeekNumber; \.$colorStyle; \.$daysOffMode; \.$daysOff; \.$allDayMode; \.$hideFinished
                \.$hideDeclined; \.$showEmptyDays; \.$allCalendars
            }
        } otherwise: {
            Summary {
                \.$app; \.$dayCount; \.$columns; \.$startDay; \.$lines; \.$fontSize; \.$showStartTime
                \.$showWeekNumber; \.$colorStyle; \.$daysOffMode; \.$daysOff; \.$allDayMode; \.$hideFinished
                \.$hideDeclined; \.$showEmptyDays; \.$allCalendars; \.$calendars
            }
        }
    }

    init() {}

    var settings: WeekSettings {
        var s = WeekSettings()
        s.dayCount = dayCount.value
        s.columns = columns.value
        s.startDay = startDay
        s.lines = lines
        s.fontSize = fontSize
        s.showStartTime = showStartTime
        s.showWeekNumber = showWeekNumber
        s.colorStyle = colorStyle
        s.daysOffMode = daysOffMode
        s.daysOff = Set((daysOff ?? []).map(\.number))
        s.allDayMode = allDayMode
        s.hideFinished = hideFinished
        s.hideDeclined = hideDeclined
        s.showEmptyDays = showEmptyDays
        s.app = app
        s.calendarIDs = allCalendars ? nil : Set((calendars ?? []).map(\.id))
        return s
    }
}
