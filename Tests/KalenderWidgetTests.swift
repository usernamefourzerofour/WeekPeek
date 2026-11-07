import XCTest
import SwiftUI
@testable import KalenderWidget

final class DayLayoutTests: XCTestCase {
    var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Copenhagen")!
        c.locale = Locale(identifier: "da_DK")
        c.firstWeekday = 2
        return c
    }()

    func d(_ day: Int, _ h: Int = 0, _ m: Int = 0) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 11, day: day, hour: h, minute: m))!
    }

    func ev(_ title: String, _ s: Date, _ e: Date, allDay: Bool = false, declined: Bool = false) -> WidgetEvent {
        WidgetEvent(id: title, title: title, start: s, end: e, isAllDay: allDay, color: RGB(r: 1, g: 0, b: 0), isDeclined: declined)
    }

    func testDaysStartTodayAndClamp() {
        let days = DayLayout.dayStarts(now: d(1, 18), count: 5, calendar: cal)
        XCTAssertEqual(days.first, d(1))
        XCTAssertEqual(days.last, d(5))
        XCTAssertEqual(DayLayout.dayStarts(now: d(1), count: 0, calendar: cal).count, 1)
        XCTAssertEqual(DayLayout.dayStarts(now: d(1), count: 20, calendar: cal).count, 14)
    }

    func testWeekStart() {
        // Wed 4 Nov 2026 → Monday 2 Nov with a Danish calendar.
        XCTAssertEqual(DayLayout.firstDay(now: d(4, 9), start: .monday, calendar: cal), d(2))
    }

    func testFixedWeekdayStart() {
        // Wed 4 Nov 2026: Wednesday → today, Sunday → 1 Nov, Thursday → 29 Oct.
        XCTAssertEqual(DayLayout.firstDay(now: d(4, 9), start: .wednesday, calendar: cal), d(4))
        XCTAssertEqual(DayLayout.firstDay(now: d(4, 9), start: .sunday, calendar: cal), d(1))
        XCTAssertEqual(DayLayout.firstDay(now: d(4, 9), start: .thursday, calendar: cal),
                       cal.date(from: DateComponents(year: 2026, month: 10, day: 29))!)
    }

    func testGridClampsPerSize() {
        var s = WeekSettings()
        XCTAssertEqual(s.grid(for: .medium), GridSpec(days: 5, columns: 5))
        XCTAssertEqual(s.grid(for: .large).rows, 2)
        s.dayCount = 8; s.columns = 5
        XCTAssertEqual(s.grid(for: .medium).rows, 2)
        XCTAssertEqual(s.grid(for: .small), GridSpec(days: 8, columns: 5), "Small allows dense layouts for StandBy")
        s.dayCount = 14; s.columns = 7
        XCTAssertEqual(s.grid(for: .small), GridSpec(days: 14, columns: 7))
        s.dayCount = 3; s.columns = 7
        XCTAssertEqual(s.grid(for: .large).columns, 3, "No more columns than days")
        s.dayCount = 10; s.columns = nil
        XCTAssertEqual(s.grid(for: .medium), GridSpec(days: 10, columns: 5), "Auto columns per size")
        XCTAssertEqual(WeekSettings().grid(for: .extraLarge), GridSpec(days: 14, columns: 7), "iPad extra large")
        var f = WeekSettings()
        f.fontSize = 3; XCTAssertEqual(f.clampedFontSize, 6, "Text size below the range is drawn at 6 pt")
        f.fontSize = 30; XCTAssertEqual(f.clampedFontSize, 20)
        XCTAssertEqual(DayCountOption.d14.value, 14)
        XCTAssertNil(ColumnsOption.auto.value)
    }

    func testFiltersAndSorting() {
        let list = [ev("B", d(2, 10), d(2, 11)), ev("Heldag", d(2), d(2, 23, 59), allDay: true),
                    ev("A", d(2, 8), d(2, 9)), ev("Nej", d(2, 12), d(2, 13), declined: true)]
        var s = WeekSettings()
        XCTAssertEqual(DayLayout.events(on: d(2), from: list, now: d(1), settings: s, calendar: cal).map(\.title),
                       ["Heldag", "A", "B", "Nej"])
        s.hideDeclined = true; s.allDayMode = .hide
        XCTAssertEqual(DayLayout.events(on: d(2), from: list, now: d(1), settings: s, calendar: cal).map(\.title), ["A", "B"])
    }

    func testHideFinishedKeepsOngoingAndAllDay() {
        let list = [ev("Slut", d(1, 8), d(1, 9)), ev("Igang", d(1, 17), d(1, 19)),
                    ev("Heldag", d(1), d(1, 23, 59), allDay: true)]
        var s = WeekSettings(); s.hideFinished = true
        XCTAssertEqual(DayLayout.events(on: d(1), from: list, now: d(1, 18), settings: s, calendar: cal).map(\.title),
                       ["Heldag", "Igang"])
    }

    func testMultiDayEventOnEachDayButTimeOnlyFirst() {
        let e = ev("Ferie", d(2, 12), d(4, 12))
        var s = WeekSettings(); s.showStartTime = true
        for day in [2, 3, 4] {
            XCTAssertEqual(DayLayout.events(on: d(day), from: [e], now: d(1), settings: s, calendar: cal).count, 1)
        }
        XCTAssertTrue(DayLayout.showsStartTime(e, on: d(2), settings: s, calendar: cal))
        XCTAssertFalse(DayLayout.showsStartTime(e, on: d(3), settings: s, calendar: cal))
    }

    func testDaysOff() {
        var s = WeekSettings()
        XCTAssertTrue(DayLayout.isDayOff(d(1), settings: s, calendar: cal))   // Sunday
        XCTAssertFalse(DayLayout.isDayOff(d(4), settings: s, calendar: cal))  // Wednesday
        s.daysOffMode = .custom; s.daysOff = [WeekdayOption.wednesday.number]
        XCTAssertTrue(DayLayout.isDayOff(d(4), settings: s, calendar: cal))
        XCTAssertFalse(DayLayout.isDayOff(d(1), settings: s, calendar: cal))
    }

    func testHeadersFollowLanguage() {
        let da = DayLayout.header(for: d(2), locale: Locale(identifier: "da_DK"), calendar: cal)
        let en = DayLayout.header(for: d(2), locale: Locale(identifier: "en_US"), calendar: cal)
        XCTAssertTrue(da.lowercased().contains("man"), da)
        XCTAssertTrue(en.contains("Mon"), en)
        XCTAssertEqual(DayLayout.weekNumber(d(2), calendar: cal), 45)
    }

    func testHeaderStyleShortensForNarrowColumns() {
        let en = Locale(identifier: "en_US")
        let days = (2...6).map { d($0) }
        XCTAssertEqual(DayLayout.headerStyle(for: days, width: 120, font: 11, locale: en, calendar: cal), .full)
        XCTAssertEqual(DayLayout.headerStyle(for: days, width: 4, font: 11, locale: en, calendar: cal), .number)
        XCTAssertEqual(DayLayout.header(for: d(2), style: .number, locale: en, calendar: cal), "2")
        let narrow = DayLayout.header(for: d(2), style: .narrow, locale: en, calendar: cal)
        XCTAssertTrue(narrow.contains("M") && narrow.contains("2"), narrow)
    }

    func testDensityForNarrowColumns() {
        let en = Locale(identifier: "en_US")
        let days = (2...8).map { d($0) }
        let wide = DayLayout.density(for: days, columnWidth: 100, style: .calendar, font: 11, locale: en, calendar: cal)
        XCTAssertEqual(wide, DayLayout.Density())
        let narrow = DayLayout.density(for: days, columnWidth: 18, style: .calendar, font: 11, locale: en, calendar: cal)
        XCTAssertFalse(narrow.showsTimes)
        XCTAssertFalse(narrow.showsTitles)
        XCTAssertTrue(narrow.shortMore)
    }

    func testRepeatedWeekLabelIsHidden() {
        // Mon–Wed and Thu–Fri of week 45: only the first row is labelled.
        XCTAssertEqual(DayLayout.showsWeekLabel(rows: [[d(2), d(3), d(4)], [d(5), d(6)]], calendar: cal), [true, false])
        // Fri–Sun (45) then Mon (46): new week, new label.
        XCTAssertEqual(DayLayout.showsWeekLabel(rows: [[d(6), d(7), d(8)], [d(9)]], calendar: cal), [true, true])
        // Sat–Mon (45–46) then Tue (46): already labelled.
        XCTAssertEqual(DayLayout.showsWeekLabel(rows: [[d(7), d(8), d(9)], [d(10)]], calendar: cal), [true, false])
    }
}

final class LineFitTests: XCTestCase {
    let font: CGFloat = 11

    func testEverythingFitsKeepsWantedLines() {
        let p = LineFit.plan(needed: [2, 1, 3], height: 500, font: font, option: .auto)
        XCTAssertEqual(p, LineFit.Plan(lines: [2, 1, 3], more: 0))
    }

    func testAutoShrinksLongestFirst() {
        let h = LineFit.total([2, 1, 2], font: font)
        let p = LineFit.plan(needed: [3, 1, 3], height: h, font: font, option: .auto)
        XCTAssertEqual(p.lines, [2, 1, 2])
        XCTAssertEqual(p.more, 0)
    }

    func testFixedLinesDoNotShrinkButShowMore() {
        let h = LineFit.total([2, 2], font: font) + LineFit.chipSpacing + 1
        let p = LineFit.plan(needed: [3, 3, 3], height: h, font: font, option: .two)
        XCTAssertEqual(p.lines, [2])
        XCTAssertEqual(p.more, 2)
    }

    func testOverflowAlwaysLeavesRoomForMore() {
        let p = LineFit.plan(needed: Array(repeating: 1, count: 20), height: 120, font: font, option: .auto)
        XCTAssertGreaterThan(p.more, 0)
        XCTAssertLessThanOrEqual(LineFit.total(p.lines, font: font) + LineFit.chipSpacing + LineFit.moreHeight(font: font), 120)
    }

    func testLongerTitleNeedsMoreLines() {
        XCTAssertEqual(LineFit.estimatedLines("Kort", width: 60, font: font), 1)
        XCTAssertGreaterThan(LineFit.estimatedLines("Foredrag på biblioteket om lokalhistorie", width: 60, font: font), 2)
    }
}

final class DeepLinkTests: XCTestCase {
    var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Copenhagen")!
        return c
    }()

    func testRoundTrip() {
        let date = cal.date(from: DateComponents(year: 2026, month: 11, day: 2))!
        let url = DeepLink.url(app: .fantastical, date: date, calendar: cal)
        XCTAssertEqual(url.absoluteString, "kalenderwidget://open?app=fantastical&date=2026-11-02")
        let parsed = DeepLink.parse(url, calendar: cal)
        XCTAssertEqual(parsed?.app, .fantastical)
        XCTAssertEqual(parsed?.date, date)
    }

    func testTargetURLs() {
        let date = cal.date(from: DateComponents(year: 2026, month: 11, day: 2))!
        XCTAssertEqual(CalendarApp.google.targetURL(for: date, calendar: cal).absoluteString, "googlecalendar://")
        XCTAssertEqual(CalendarApp.outlook.targetURL(for: date, calendar: cal).absoluteString, "ms-outlook://events")
        XCTAssertEqual(CalendarApp.fantastical.targetURL(for: date, calendar: cal).absoluteString,
                       "x-fantastical3://show?date=2026-11-02")
        XCTAssertTrue(CalendarApp.apple.targetURL(for: date, calendar: cal).absoluteString.hasPrefix("calshow:"))
    }
}

/// Saves PNGs of the widget for visual review: every size, several settings, English and Danish.
final class RenderTests: XCTestCase {
    struct Variant {
        let name: String
        let size: WidgetSize
        var configure: (inout WeekSettings) -> Void = { _ in }
        var scheme: ColorScheme = .light
        var accented = false
        /// Overrides the iPhone size, e.g. for iPad widgets.
        var frame: CGSize? = nil
    }

    /// iPad Pro 13" widget sizes (points).
    static let iPad: [WidgetSize: CGSize] = [
        .small: CGSize(width: 170, height: 170),
        .medium: CGSize(width: 379, height: 170),
        .large: CGSize(width: 379, height: 379),
        .extraLarge: CGSize(width: 795, height: 379),
    ]

    static let sizes: [WidgetSize: CGSize] = [
        .small: CGSize(width: 158, height: 158),
        .medium: CGSize(width: 338, height: 158),
        .large: CGSize(width: 338, height: 354),
    ]

    @MainActor
    func testRenderPreviews() throws {
        guard let home = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] else {
            throw XCTSkip("Simulator only")
        }
        let dir = URL(fileURLWithPath: home).appendingPathComponent("drive/src/renders/r3")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let variants: [Variant] = [
            Variant(name: "small", size: .small),
            Variant(name: "small-5days-3cols-week", size: .small,
                    configure: { $0.dayCount = 5; $0.columns = 3; $0.showWeekNumber = true }, scheme: .dark),
            Variant(name: "small-5cols", size: .small,
                    configure: { $0.dayCount = 5; $0.columns = 5 }, scheme: .dark),
            Variant(name: "small-14days-7cols", size: .small,
                    configure: { $0.dayCount = 14; $0.columns = 7; $0.fontSize = 8; $0.showStartTime = false }, scheme: .dark),
            Variant(name: "medium", size: .medium),
            Variant(name: "medium-dark", size: .medium, scheme: .dark),
            Variant(name: "medium-tinted", size: .medium, scheme: .dark, accented: true),
            Variant(name: "medium-stripe-time-week", size: .medium) {
                $0.colorStyle = .stripe; $0.showStartTime = true; $0.showWeekNumber = true
            },
            Variant(name: "medium-10days-2rows-mono", size: .medium) {
                $0.dayCount = 10; $0.columns = 5; $0.colorStyle = .mono; $0.showWeekNumber = true
            },
            Variant(name: "medium-font14-lines1", size: .medium) { $0.fontSize = 14; $0.lines = .one },
            Variant(name: "medium-font8-alldaytop", size: .medium) { $0.fontSize = 8; $0.allDayMode = .top },
            Variant(name: "medium-font6", size: .medium) { $0.fontSize = 6 },
            Variant(name: "small-5cols-font6", size: .small, configure: { $0.dayCount = 5; $0.columns = 5; $0.fontSize = 6 }, scheme: .dark),
            Variant(name: "large", size: .large),
            Variant(name: "large-weekstart-week-time", size: .large) {
                $0.startDay = .monday; $0.showWeekNumber = true; $0.showStartTime = true
            },
            Variant(name: "ipad-small", size: .small, frame: Self.iPad[.small]),
            Variant(name: "ipad-medium", size: .medium, frame: Self.iPad[.medium]),
            Variant(name: "ipad-large", size: .large, frame: Self.iPad[.large]),
            Variant(name: "ipad-xl", size: .extraLarge, frame: Self.iPad[.extraLarge]),
            Variant(name: "ipad-xl-dark-week-time", size: .extraLarge,
                    configure: { $0.startDay = .monday; $0.showWeekNumber = true },
                    scheme: .dark, frame: Self.iPad[.extraLarge]),
            Variant(name: "ipad-xl-7days-1row", size: .extraLarge,
                    configure: { $0.dayCount = 7; $0.columns = 7; $0.fontSize = 13 }, frame: Self.iPad[.extraLarge]),
        ]
        let now = Date()
        for lang in ["en_US", "da_DK"] {
            for v in variants {
                var s = WeekSettings()
                v.configure(&s)
                let model = WeekModel.sample(now: now, settings: s)
                let frame = v.frame ?? Self.sizes[v.size]!
                let bg: Color = v.accented ? Color(red: 0.25, green: 0.30, blue: 0.40) : (v.scheme == .dark ? Color(white: 0.11) : .white)
                let view = WeekWidgetView(model: model, size: v.size, accentedOverride: v.accented)
                    .frame(width: frame.width, height: frame.height)
                    .background(bg)
                    .environment(\.colorScheme, v.scheme)
                    .environment(\.locale, Locale(identifier: lang))
                try save(view, to: dir.appendingPathComponent("\(lang.prefix(2))-\(v.name).png"))
            }
        }
    }

    @MainActor
    private func save(_ view: some View, to url: URL, scale: CGFloat = 3) throws {
        let r = ImageRenderer(content: view)
        r.scale = scale
        try XCTUnwrap(r.uiImage?.pngData()).write(to: url)
    }

    static let languages = ["en", "ar", "bg", "ca", "cs", "da", "de", "el", "es", "es-419", "fi", "fr", "he", "hi", "hr", "hu", "id", "it", "ja", "ko", "lt", "ms", "nb", "nl", "pl", "pt-BR", "pt-PT", "ro", "ru", "sk", "sl", "sv", "th", "tr", "uk", "vi", "zh-Hans", "zh-Hant"]

    /// One sheet per five languages: small, medium (start time + week number) and large widget side by side.
    @MainActor
    func testLanguageSheets() throws {
        guard let home = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] else {
            throw XCTSkip("Simulator only")
        }
        let dir = URL(fileURLWithPath: home).appendingPathComponent("drive/src/renders/lang")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let now = Date()
        var medium = WeekSettings(); medium.showWeekNumber = true
        var large = WeekSettings(); large.showWeekNumber = true; large.startDay = .monday
        let groups = stride(from: 0, to: Self.languages.count, by: 5).map {
            Array(Self.languages[$0..<min($0 + 5, Self.languages.count)])
        }
        for (g, langs) in groups.enumerated() {
            let sheet = VStack(alignment: .leading, spacing: 14) {
                ForEach(langs, id: \.self) { lang in
                    let rtl = Locale.Language(identifier: lang).characterDirection == .rightToLeft
                    HStack(alignment: .top, spacing: 12) {
                        Text(verbatim: lang).font(.system(size: 14, weight: .bold)).frame(width: 60, alignment: .leading)
                        WeekWidgetView(model: .sample(now: now), size: .small).frame(width: 158, height: 158)
                            .background(Color.white)
                        WeekWidgetView(model: .sample(now: now, settings: medium), size: .medium).frame(width: 338, height: 158)
                            .background(Color.white)
                        WeekWidgetView(model: .sample(now: now, settings: large), size: .large).frame(width: 338, height: 354)
                            .background(Color.white)
                    }
                    .environment(\.locale, Locale(identifier: lang))
                    .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
                }
            }
            .padding(12)
            .background(Color(white: 0.85))
            .environment(\.colorScheme, .light)
            try save(sheet, to: dir.appendingPathComponent(String(format: "sheet-%02d.png", g + 1)), scale: 2)
        }
    }
}
