import Foundation
import AppIntents

/// Calendar apps we can open. Only apps with a known URL scheme are included.
enum CalendarApp: String, AppEnum, CaseIterable, Hashable {
    case google, apple, outlook, fantastical

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Calendar app"
    static let caseDisplayRepresentations: [CalendarApp: DisplayRepresentation] = [
        .google: "Google Calendar",
        .apple: "Apple Calendar",
        .outlook: "Microsoft Outlook",
        .fantastical: "Fantastical",
    ]

    var displayName: String {
        switch self {
        case .google: return String(localized: "Google Calendar")
        case .apple: return String(localized: "Apple Calendar")
        case .outlook: return "Microsoft Outlook"
        case .fantastical: return "Fantastical"
        }
    }

    /// Only Apple Calendar and Fantastical have documented date links; the others open on today.
    var supportsDate: Bool { self == .apple || self == .fantastical }

    var rootURL: URL {
        switch self {
        case .google: return URL(string: "googlecalendar://")!
        case .apple: return URL(string: "calshow://")!
        // Undocumented by Microsoft, but opens Outlook on iOS.
        case .outlook: return URL(string: "ms-outlook://")!
        case .fantastical: return URL(string: "x-fantastical3://")!
        }
    }

    func targetURL(for date: Date?, calendar: Calendar = .current) -> URL {
        guard let date, supportsDate else { return rootURL }
        switch self {
        case .apple:
            // calshow:<seconds since 2001-01-01>. Noon avoids time zone edges.
            let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
            return URL(string: "calshow:\(Int(noon.timeIntervalSinceReferenceDate))")!
        case .fantastical:
            return URL(string: "x-fantastical3://show?date=\(DeepLink.dayString(date, calendar: calendar))")!
        case .google, .outlook:
            return rootURL
        }
    }

    var appStoreURL: URL {
        switch self {
        case .google: return URL(string: "https://apps.apple.com/app/id909319292")!
        case .apple: return URL(string: "https://apps.apple.com/app/id1108185179")!
        case .outlook: return URL(string: "https://apps.apple.com/app/id951937596")!
        case .fantastical: return URL(string: "https://apps.apple.com/app/id718043190")!
        }
    }
}
