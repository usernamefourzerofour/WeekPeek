import SwiftUI
import WidgetKit
import UIKit

enum Metrics {
    static let columnSpacing: CGFloat = 4
    static let rowSpacing: CGFloat = 6
}

/// Home-screen widget in all three sizes. Also rendered by the tests.
struct WeekWidgetView: View {
    let model: WeekModel
    let size: WidgetSize
    /// Only for tests – in the widget the system decides.
    var accentedOverride: Bool? = nil

    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.locale) private var locale
    private var accented: Bool { accentedOverride ?? (renderingMode == .accented) }
    private var calendar: Calendar {
        var c = Calendar.current
        c.locale = locale
        return c
    }

    var body: some View {
        if model.hasAccess {
            grid
        } else {
            VStack(spacing: 6) {
                Image(systemName: "calendar.badge.exclamationmark").font(.title2)
                Text("Open WeekPeek and allow calendar access")
                    .font(.caption).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .widgetURL(DeepLink.setupURL)
        }
    }

    private var grid: some View {
        let s = model.settings
        let spec = s.grid(for: size)
        let days = DayLayout.dayStarts(now: model.now, count: spec.days, start: s.startDay, calendar: calendar)
        let rows = stride(from: 0, to: days.count, by: spec.columns).map { Array(days[$0..<min($0 + spec.columns, days.count)]) }
        let font = s.clampedFontSize
        let labelH = LineFit.weekLabelHeight(font: font)
        let labels = s.showWeekNumber ? DayLayout.showsWeekLabel(rows: rows, calendar: calendar) : rows.map { _ in false }
        let labelCount = CGFloat(labels.filter { $0 }.count)
        return GeometryReader { geo in
            let usable = geo.size.height - labelH * labelCount - Metrics.rowSpacing * CGFloat(rows.count - 1)
            let rowH = usable / CGFloat(max(1, rows.count))
            let colW = (geo.size.width - Metrics.columnSpacing * CGFloat(spec.columns - 1)) / CGFloat(spec.columns)
            let density = DayLayout.density(for: days, columnWidth: colW, style: s.colorStyle, font: font,
                                            locale: locale, calendar: calendar)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { r, row in
                    if r > 0 {
                        // With week labels, the label line separates the weeks instead.
                        if labels[r] {
                            Color.clear.frame(height: Metrics.rowSpacing)
                        } else {
                            separator.frame(height: 0.5).frame(maxWidth: .infinity)
                                .padding(.vertical, (Metrics.rowSpacing - 0.5) / 2)
                        }
                    }
                    if labels[r] {
                        weekLabel(row, font: font).frame(height: labelH)
                    }
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(0..<spec.columns, id: \.self) { c in
                            if c > 0 {
                                separator.frame(width: 0.5, height: rowH)
                                    .padding(.horizontal, (Metrics.columnSpacing - 0.5) / 2)
                            }
                            if c < row.count {
                                cell(day: row[c], width: colW, height: rowH, density: density)
                            } else {
                                Color.clear.frame(width: colW, height: rowH)
                            }
                        }
                    }
                }
            }
        }
        .padding(size.padding)
        .widgetURL(DeepLink.url(app: s.app, date: model.now, calendar: calendar))
    }

    private var separator: some View {
        Rectangle().fill(accented ? Color.primary.opacity(0.25) : Color(uiColor: .separator))
    }

    /// "Week 45" (or "Week 45–46" when the row crosses a week boundary) followed by a hairline.
    private func weekLabel(_ row: [Date], font: CGFloat) -> some View {
        let first = DayLayout.weekNumber(row.first!, calendar: calendar)
        let last = DayLayout.weekNumber(row.last!, calendar: calendar)
        return HStack(spacing: 6) {
            Group {
                if first == last {
                    Text("Week \(first)")
                } else {
                    Text("Week \(first)–\(last)")
                }
            }
            .font(.system(size: font * 0.85, weight: .semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize()
            separator.frame(height: 0.5).frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func cell(day: Date, width: CGFloat, height: CGFloat, density: DayLayout.Density) -> some View {
        let column = DayColumn(model: model, day: day, width: width, height: height, density: density,
                               calendar: calendar, locale: locale, accented: accented)
        if size == .small {
            column  // Small widgets only support a single tap target.
        } else {
            Link(destination: DeepLink.url(app: model.settings.app, date: day, calendar: calendar)) { column }
                .buttonStyle(.plain)
        }
    }

}

struct DayColumn: View {
    let model: WeekModel
    let day: Date
    let width: CGFloat
    let height: CGFloat
    var density = DayLayout.Density()
    let calendar: Calendar
    let locale: Locale
    let accented: Bool

    private var s: WeekSettings { model.settings }
    private var font: CGFloat { s.clampedFontSize }

    var body: some View {
        let isToday = calendar.isDate(day, inSameDayAs: model.now)
        let events = DayLayout.events(on: day, from: model.events, now: model.now, settings: s, calendar: calendar)
        let (allDay, timed) = s.allDayMode == .top
            ? (events.filter(\.isAllDay), events.filter { !$0.isAllDay })
            : ([], events)
        let headerH = LineFit.headerHeight(font: font)
        let topAllDayH = allDay.isEmpty ? 0 : LineFit.total(Array(repeating: 1, count: allDay.count), font: font) + 4
        let available = height - headerH - topAllDayH
        let textW = LineFit.textWidth(chipWidth: width, style: s.colorStyle)
        let scales = timed.map { LineFit.wordFitScale($0.title, width: textW, font: font) }
        // A word that cannot fit is truncated on its line rather than wrapped mid-word:
        // one line, or two when the start time takes the first line.
        let needed = !density.showsTitles ? timed.map { _ in 1 } : zip(timed, scales).map { event, scale in
            let timeLine = timePrefix(for: event) == nil ? 0 : 1
            return timeLine + (scale < LineFit.minWordScale ? 1
                : LineFit.estimatedLines(event.title, width: textW, font: font * scale))
        }
        let plan = LineFit.plan(needed: needed, height: available, font: font, option: s.lines)

        VStack(alignment: .leading, spacing: LineFit.chipSpacing) {
            header(isToday: isToday)
                .frame(height: headerH - LineFit.chipSpacing, alignment: .bottomLeading)

            if !allDay.isEmpty {
                ForEach(allDay) { EventChip(event: $0, text: density.showsTitles ? $0.title : "", lines: 1, font: font, style: s.colorStyle, accented: accented) }
                Rectangle().fill(Color.primary.opacity(0.15)).frame(height: 0.5).padding(.vertical, 1)
            }

            ForEach(Array(zip(timed.prefix(plan.lines.count), plan.lines).enumerated()), id: \.element.0.id) { i, pair in
                let (event, lines) = pair
                EventChip(event: event, text: title(for: event), timePrefix: timePrefix(for: event),
                          lines: lines, font: font, style: s.colorStyle, accented: accented,
                          scale: lines > 1 && scales[i] >= LineFit.minWordScale ? scales[i] : 1)
            }

            if plan.more > 0 {
                Group {
                    if density.shortMore { Text(verbatim: "+\(plan.more)") } else { Text("+\(plan.more) more") }
                }
                    .font(.system(size: font * 0.9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else if events.isEmpty && s.showEmptyDays {
                Text(verbatim: "–")
                    .font(.system(size: font, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel(Text("No events"))
            }
            Spacer(minLength: 0)
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .background {
            if DayLayout.isDayOff(day, settings: s, calendar: calendar) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.primary.opacity(accented ? 0.10 : 0.06))
                    .padding(-2)
            }
        }
        .contentShape(Rectangle())
    }

    private func header(isToday: Bool) -> some View {
        Text(DayLayout.header(for: day, style: density.header, locale: locale, calendar: calendar))
            .font(.system(size: font + 1, weight: isToday ? .bold : .semibold))
            .foregroundStyle(isToday ? Color.red : Color.primary)
            .widgetAccentable(isToday)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private func timePrefix(for e: WidgetEvent) -> String? {
        density.showsTitles && density.showsTimes && DayLayout.showsStartTime(e, on: day, settings: s, calendar: calendar)
            ? DayLayout.startTime(e.start, locale: locale, calendar: calendar) : nil
    }

    /// Text used for the line estimate, including any start time.
    private func title(for e: WidgetEvent) -> String {
        if !density.showsTitles { return "" }
        if let t = timePrefix(for: e) { return t + " " + e.title }
        return e.title
    }
}

struct EventChip: View {
    let event: WidgetEvent
    let text: String
    var timePrefix: String? = nil
    let lines: Int
    let font: CGFloat
    let style: ColorStyle
    let accented: Bool
    /// Shrinks only this chip's text when a single word is wider than the column.
    var scale: CGFloat = 1

    var body: some View {
        let pad = LineFit.verticalPadding(font: font)
        content
            .foregroundStyle(textColor)
            .padding(.vertical, pad)
            .padding(.leading, style == .stripe ? 6 : 3)
            .padding(.trailing, 3)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: LineFit.chipHeight(lines: lines, font: font), alignment: .topLeading)
            .background(alignment: .leading) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous).fill(fill)
                    if style == .stripe && !accented {
                        UnevenRoundedRectangle(topLeadingRadius: 3, bottomLeadingRadius: 3, style: .continuous)
                            .fill(event.color.color)
                            .frame(width: 3)
                    }
                }
            }
            .opacity(event.isDeclined ? 0.55 : 1)
    }

    /// With room for two or more lines the start time gets its own line, so it is never split.
    @ViewBuilder private var content: some View {
        if let timePrefix, lines >= 2 {
            VStack(alignment: .leading, spacing: 0) {
                Text(timePrefix)
                    .font(.system(size: font, weight: .bold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(titleAttributed)
                    .font(.system(size: font * scale, weight: .medium))
                    .lineLimit(lines - 1)
                    .truncationMode(.tail)
            }
        } else {
            Text(attributed)
                .font(.system(size: font * scale, weight: .medium))
                .lineLimit(lines)
                .truncationMode(.tail)
        }
    }

    private var titleAttributed: AttributedString {
        var body = AttributedString(event.title)
        if event.isDeclined { body.strikethroughStyle = .single }
        return body
    }

    private var attributed: AttributedString {
        let title = timePrefix == nil ? text : event.title
        var result = AttributedString()
        if let timePrefix {
            var t = AttributedString(timePrefix + " ")
            t.font = .system(size: font * scale, weight: .bold).monospacedDigit()
            result += t
        }
        var body = AttributedString(title)
        if event.isDeclined { body.strikethroughStyle = .single }
        result += body
        return result
    }

    private var fill: Color {
        if accented { return Color.primary.opacity(0.18) }
        switch style {
        case .calendar: return event.color.color
        case .stripe, .mono: return Color.primary.opacity(0.09)
        }
    }

    private var textColor: Color {
        if accented { return .primary }
        return style == .calendar ? event.color.textColor : .primary
    }
}
