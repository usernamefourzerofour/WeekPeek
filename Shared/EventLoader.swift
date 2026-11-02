import Foundation
import EventKit
import UIKit

enum EventLoader {
    static var hasAccess: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    static func load(from start: Date, to end: Date, calendarIDs: Set<String>?,
                     store: EKEventStore = EKEventStore()) -> [WidgetEvent] {
        guard hasAccess else { return [] }
        var calendars = store.calendars(for: .event)
        if let ids = calendarIDs, !ids.isEmpty {
            calendars = calendars.filter { ids.contains($0.calendarIdentifier) }
        }
        guard !calendars.isEmpty else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return store.events(matching: predicate).map { ev in
            let title = (ev.title ?? "").trimmingCharacters(in: .whitespaces)
            let id = (ev.eventIdentifier ?? UUID().uuidString) + "@\(ev.startDate.timeIntervalSince1970)"
            let declined = ev.attendees?.first(where: \.isCurrentUser)?.participantStatus == .declined
            return WidgetEvent(id: id,
                               title: title.isEmpty ? String(localized: "(No title)") : title,
                               start: ev.startDate,
                               end: ev.endDate,
                               isAllDay: ev.isAllDay,
                               color: rgb(ev.calendar?.cgColor),
                               isDeclined: declined)
        }
    }

    static func rgb(_ cg: CGColor?) -> RGB {
        guard let cg else { return RGB(r: 0.5, g: 0.5, b: 0.5) }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(cgColor: cg).getRed(&r, green: &g, blue: &b, alpha: &a)
        return RGB(r: Double(r), g: Double(g), b: Double(b))
    }
}
