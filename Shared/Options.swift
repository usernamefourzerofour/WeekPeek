import Foundation
import AppIntents

/// Choices in "Edit Widget". Display names are English keys, translated in Localizable.xcstrings.

/// Today, or a fixed weekday (the latest one on or before today).
enum StartDay: String, AppEnum, CaseIterable, Hashable {
    case today, monday, tuesday, wednesday, thursday, friday, saturday, sunday
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Start day"
    static let caseDisplayRepresentations: [StartDay: DisplayRepresentation] = [
        .today: "Today",
        .monday: "Monday", .tuesday: "Tuesday", .wednesday: "Wednesday", .thursday: "Thursday",
        .friday: "Friday", .saturday: "Saturday", .sunday: "Sunday",
    ]
    /// Calendar weekday number (1 = Sunday … 7 = Saturday) for the fixed weekdays.
    var weekday: Int? { WeekdayOption(rawValue: rawValue)?.number }
}

enum LinesOption: String, AppEnum, CaseIterable, Hashable {
    case auto, one, two, three
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Lines per event"
    static let caseDisplayRepresentations: [LinesOption: DisplayRepresentation] = [
        .auto: "Auto", .one: "1", .two: "2", .three: "3",
    ]
    var isAuto: Bool { self == .auto }
    /// Upper limit. Auto allows up to 3 and shrinks the longest titles first when space runs out.
    var maxLines: Int {
        switch self {
        case .auto, .three: return 3
        case .one: return 1
        case .two: return 2
        }
    }
}

enum ColorStyle: String, AppEnum, CaseIterable, Hashable {
    case calendar, stripe, mono
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Colors"
    static let caseDisplayRepresentations: [ColorStyle: DisplayRepresentation] = [
        .calendar: "Calendar colors",
        .stripe: "Color stripe",
        .mono: "Single color",
    ]
}

enum DaysOffMode: String, AppEnum, CaseIterable, Hashable {
    case none, weekend, custom
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Days off"
    static let caseDisplayRepresentations: [DaysOffMode: DisplayRepresentation] = [
        .none: "None",
        .weekend: "Weekend",
        .custom: "Choose days",
    ]
}

enum AllDayMode: String, AppEnum, CaseIterable, Hashable {
    case show, top, hide
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "All-day events"
    static let caseDisplayRepresentations: [AllDayMode: DisplayRepresentation] = [
        .show: "Show",
        .top: "Group at top",
        .hide: "Hide",
    ]
}

/// "Auto" follows the widget size; a number overrides it.
enum DayCountOption: String, AppEnum, CaseIterable, Hashable {
    case auto, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Number of days"
    static let caseDisplayRepresentations: [DayCountOption: DisplayRepresentation] = [
        .auto: "Auto", .d1: "1", .d2: "2", .d3: "3", .d4: "4", .d5: "5", .d6: "6", .d7: "7",
        .d8: "8", .d9: "9", .d10: "10", .d11: "11", .d12: "12", .d13: "13", .d14: "14",
    ]
    var value: Int? { self == .auto ? nil : Int(rawValue.dropFirst()) }
}

enum ColumnsOption: String, AppEnum, CaseIterable, Hashable {
    case auto, c1, c2, c3, c4, c5, c6, c7
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Columns"
    static let caseDisplayRepresentations: [ColumnsOption: DisplayRepresentation] = [
        .auto: "Auto", .c1: "1", .c2: "2", .c3: "3", .c4: "4", .c5: "5", .c6: "6", .c7: "7",
    ]
    var value: Int? { self == .auto ? nil : Int(rawValue.dropFirst()) }
}

enum WeekdayOption: String, AppEnum, CaseIterable, Hashable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Weekday"
    static let caseDisplayRepresentations: [WeekdayOption: DisplayRepresentation] = [
        .monday: "Monday", .tuesday: "Tuesday", .wednesday: "Wednesday", .thursday: "Thursday",
        .friday: "Friday", .saturday: "Saturday", .sunday: "Sunday",
    ]
    /// Calendar weekday number: 1 = Sunday … 7 = Saturday.
    var number: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
}
