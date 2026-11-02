import WidgetKit
import SwiftUI

@main
struct KalenderWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeekWidget()
    }
}

extension WidgetFamily {
    var size: WidgetSize {
        switch self {
        case .systemSmall: return .small
        case .systemLarge, .systemExtraLarge: return .large
        default: return .medium
        }
    }
}

struct WeekWidget: Widget {
    let kind = "WeekWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WeekWidgetIntent.self, provider: WeekProvider()) { entry in
            WeekWidgetView(model: entry.model, size: entry.size)
                // System background: replaced automatically in tinted, clear and StandBy modes.
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("WeekPeek")
        .description("Your upcoming events at a glance. Tap a day to open your calendar app.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct WeekEntry: TimelineEntry {
    let date: Date
    let model: WeekModel
    let size: WidgetSize
}

struct WeekProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WeekEntry {
        WeekEntry(date: .now, model: .sample(now: .now), size: context.family.size)
    }

    func snapshot(for configuration: WeekWidgetIntent, in context: Context) async -> WeekEntry {
        let now = Date()
        if context.isPreview && !EventLoader.hasAccess {
            return WeekEntry(date: now, model: .sample(now: now, settings: configuration.settings), size: context.family.size)
        }
        return makeEntries(configuration.settings, size: context.family.size, now: now).first!
    }

    func timeline(for configuration: WeekWidgetIntent, in context: Context) async -> Timeline<WeekEntry> {
        let now = Date()
        let entries = makeEntries(configuration.settings, size: context.family.size, now: now)
        // Reload about every 30 min to catch calendar changes. iOS may wait longer.
        return Timeline(entries: entries, policy: .after(now.addingTimeInterval(30 * 60)))
    }

    /// Precomputed entries: now, when each event ends (if finished ones are hidden) and at midnight.
    func makeEntries(_ settings: WeekSettings, size: WidgetSize, now: Date, calendar: Calendar = .current) -> [WeekEntry] {
        let spec = settings.grid(for: size)
        let first = DayLayout.firstDay(now: now, start: settings.startDay, calendar: calendar)
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        // +1 day so the midnight entry also has data for the new last day.
        let end = calendar.date(byAdding: .day, value: spec.days + 1, to: first)!
        let access = EventLoader.hasAccess
        let events = EventLoader.load(from: first, to: end, calendarIDs: settings.calendarIDs)

        var dates: Set<Date> = [now, midnight]
        if settings.hideFinished {
            for e in events where !e.isAllDay && e.end > now && e.end < midnight { dates.insert(e.end) }
        }
        return dates.sorted().map {
            WeekEntry(date: $0, model: WeekModel(now: $0, settings: settings, events: events, hasAccess: access), size: size)
        }
    }
}
