import Foundation

/// The widget can only open our own app. The link carries the chosen app and date,
/// and the app forwards the user right away (see Router).
enum DeepLink {
    static let scheme = "kalenderwidget"
    static let setupURL = URL(string: "kalenderwidget://setup")!

    static func url(app: CalendarApp, date: Date, calendar: Calendar = .current) -> URL {
        var c = URLComponents()
        c.scheme = scheme
        c.host = "open"
        c.queryItems = [
            URLQueryItem(name: "app", value: app.rawValue),
            URLQueryItem(name: "date", value: dayString(date, calendar: calendar)),
        ]
        return c.url!
    }

    static func parse(_ url: URL, calendar: Calendar = .current) -> (app: CalendarApp, date: Date?)? {
        guard url.scheme == scheme, url.host == "open",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let raw = items.first(where: { $0.name == "app" })?.value,
              let app = CalendarApp(rawValue: raw) else { return nil }
        let date = items.first(where: { $0.name == "date" })?.value.flatMap { date(from: $0, calendar: calendar) }
        return (app, date)
    }

    static func dayString(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func date(from string: String, calendar: Calendar = .current) -> Date? {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
