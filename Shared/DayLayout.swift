import Foundation
import CoreGraphics
import UIKit

/// Pure logic without UI – covered by KalenderWidgetTests.
enum DayLayout {
    static func firstDay(now: Date, start: StartDay, calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: now)
        guard let target = start.weekday else { return today }
        return latest(weekday: target, onOrBefore: today, calendar: calendar)
    }

    private static func latest(weekday target: Int, onOrBefore day: Date, calendar: Calendar) -> Date {
        let back = (calendar.component(.weekday, from: day) - target + 7) % 7
        return calendar.date(byAdding: .day, value: -back, to: day) ?? day
    }

    static func dayStarts(now: Date, count: Int, start: StartDay = .today, calendar: Calendar = .current) -> [Date] {
        let first = firstDay(now: now, start: start, calendar: calendar)
        let n = min(14, max(1, count))
        return (0..<n).compactMap { calendar.date(byAdding: .day, value: $0, to: first) }
    }

    /// Events touching the day, filtered and sorted.
    static func events(on day: Date, from all: [WidgetEvent], now: Date, settings: WeekSettings,
                       calendar: Calendar = .current) -> [WidgetEvent] {
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: day) else { return [] }
        return all.filter { e in
            let overlaps = e.start < dayEnd && (e.end > day || e.start >= day)
            guard overlaps else { return false }
            if e.isAllDay && settings.allDayMode == .hide { return false }
            if e.isDeclined && settings.hideDeclined { return false }
            // All-day events last all day; ongoing events are always shown.
            if settings.hideFinished && !e.isAllDay && e.end <= now { return false }
            return true
        }
        .sorted(by: order)
    }

    static func order(_ a: WidgetEvent, _ b: WidgetEvent) -> Bool {
        if a.isAllDay != b.isAllDay { return a.isAllDay }
        if a.start != b.start { return a.start < b.start }
        return a.title.localizedStandardCompare(b.title) == .orderedAscending
    }

    static func isDayOff(_ day: Date, settings: WeekSettings, calendar: Calendar = .current) -> Bool {
        switch settings.daysOffMode {
        case .none: return false
        case .weekend: return calendar.isDateInWeekend(day)
        case .custom: return settings.daysOff.contains(calendar.component(.weekday, from: day))
        }
    }

    /// The start time is shown only on the day a timed event starts.
    static func showsStartTime(_ e: WidgetEvent, on day: Date, settings: WeekSettings, calendar: Calendar = .current) -> Bool {
        settings.showStartTime && !e.isAllDay && calendar.isDate(e.start, inSameDayAs: day)
    }

    /// How much of the day header fits: "Mon 2" / "man. 2.", then "M 2", then just "2".
    enum HeaderStyle: CaseIterable {
        case full, narrow, number

        var template: String {
            switch self {
            case .full: return "EEEd"
            case .narrow: return "EEEEEd"
            case .number: return "d"
            }
        }
    }

    /// Day header in the user's language.
    static func header(for date: Date, style: HeaderStyle = .full, locale: Locale = .autoupdatingCurrent,
                       calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.setLocalizedDateFormatFromTemplate(style.template)
        return f.string(from: date)
    }

    /// The longest header style where every day's header fits the column (allowing a little shrinking),
    /// so all columns use the same style.
    static func headerStyle(for days: [Date], width: CGFloat, font: CGFloat,
                            locale: Locale, calendar: Calendar = .current) -> HeaderStyle {
        let f = UIFont.systemFont(ofSize: font + 1, weight: .bold)
        for style in HeaderStyle.allCases {
            let widest = days.map { (header(for: $0, style: style, locale: locale, calendar: calendar) as NSString)
                .size(withAttributes: [.font: f]).width }.max() ?? 0
            // Same safety margin as LineFit; the header may shrink to 85 % before a shorter style is used.
            if (widest * 1.08 + 2) * 0.85 <= width { return style }
        }
        return .number
    }

    /// Whether each row gets a week label: not when it shows only the week the previous row ended in.
    static func showsWeekLabel(rows: [[Date]], calendar: Calendar = .current) -> [Bool] {
        let weeks = rows.map { (weekNumber($0.first!, calendar: calendar), weekNumber($0.last!, calendar: calendar)) }
        return weeks.indices.map { r in
            r == 0 || !(weeks[r].0 == weeks[r - 1].1 && weeks[r].1 == weeks[r - 1].1)
        }
    }

    static func startTime(_ date: Date, locale: Locale, calendar: Calendar = .current) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.locale = locale
        style.calendar = calendar
        style.timeZone = calendar.timeZone
        return date.formatted(style)
    }

    static func weekNumber(_ date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.weekOfYear, from: date)
    }
}

/// Decides how many lines each event gets inside one day cell.
enum LineFit {
    static let chipSpacing: CGFloat = 2

    static func lineHeight(font: CGFloat) -> CGFloat { ceil(font * 1.22) }
    static func verticalPadding(font: CGFloat) -> CGFloat { max(1, (font * 0.12).rounded()) }

    static func chipHeight(lines: Int, font: CGFloat) -> CGFloat {
        CGFloat(lines) * lineHeight(font: font) + 2 * verticalPadding(font: font)
    }

    static func moreHeight(font: CGFloat) -> CGFloat { lineHeight(font: font * 0.9) }

    static func headerHeight(font: CGFloat) -> CGFloat { ceil((font + 1) * 1.25) + 2 }

    /// Horizontal space for text inside a chip of the given width.
    static func textWidth(chipWidth: CGFloat, style: ColorStyle) -> CGFloat {
        max(1, chipWidth - (style == .stripe ? 6 : 3) - 3)
    }

    private static func uiFont(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: .medium) }

    /// Measured number of lines the text needs at this width (word wrapping, like SwiftUI).
    static func estimatedLines(_ text: String, width: CGFloat, font: CGFloat) -> Int {
        let f = uiFont(font)
        let rect = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                                   options: [.usesLineFragmentOrigin], attributes: [.font: f], context: nil)
        return max(1, Int(ceil(rect.height / f.lineHeight - 0.05)))
    }

    static let minWordScale: CGFloat = 0.8

    /// Text scale needed for the longest word to fit on one line (1 = fits already).
    /// Below `minWordScale` the event gets a single truncated line instead of a mid-word break.
    static func wordFitScale(_ text: String, width: CGFloat, font: CGFloat) -> CGFloat {
        let f = uiFont(font)
        let words = text.split(whereSeparator: { $0 == " " || $0 == "/" })
        let longest = words.map { (String($0) as NSString).size(withAttributes: [.font: f]).width }.max() ?? 0
        guard longest > 0 else { return 1 }
        // 8 % + 2 pt margin: SwiftUI lays out text slightly wider than UIKit measures it.
        return min(1, width / (longest * 1.08 + 2))
    }

    /// Height of the "Week 45" line above each row, including a little space below it.
    static func weekLabelHeight(font: CGFloat) -> CGFloat { ceil(font * 0.85 * 1.25) + 3 }

    struct Plan: Equatable {
        var lines: [Int]   // per shown event
        var more: Int      // events that did not fit
    }

    static func total(_ lines: [Int], font: CGFloat) -> CGFloat {
        guard !lines.isEmpty else { return 0 }
        return lines.reduce(0) { $0 + chipHeight(lines: $1, font: font) } + chipSpacing * CGFloat(lines.count - 1)
    }

    /// - needed: estimated lines each event would like.
    static func plan(needed: [Int], height: CGFloat, font: CGFloat, option: LinesOption) -> Plan {
        var lines = needed.map { min(option.maxLines, max(1, $0)) }
        guard !lines.isEmpty else { return Plan(lines: [], more: 0) }

        if option.isAuto {
            // Shrink the longest titles first, one line at a time.
            while total(lines, font: font) > height, let i = indexOfLongest(lines), lines[i] > 1 {
                lines[i] -= 1
            }
        }
        if total(lines, font: font) <= height { return Plan(lines: lines, more: 0) }

        // Still too tall: show as many as fit and keep room for "+N more".
        let reserve = moreHeight(font: font) + chipSpacing
        var k = lines.count - 1
        while k > 0 && total(Array(lines.prefix(k)), font: font) + reserve > height { k -= 1 }
        return Plan(lines: Array(lines.prefix(k)), more: lines.count - k)
    }

    /// The last of the events with the most lines, so earlier events keep their text longest.
    private static func indexOfLongest(_ lines: [Int]) -> Int? {
        guard let m = lines.max(), m > 1 else { return nil }
        return lines.lastIndex(of: m)
    }
}
