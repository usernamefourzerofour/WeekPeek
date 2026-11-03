# App Store listing (draft)

Working notes for the App Store Connect listing. English is the primary language; other languages can reuse the English text or be translated later.

## Basics

| Field | Value | Limit |
| --- | --- | --- |
| Name | WeekPeek: Calendar Widget | 30 |
| Subtitle | Your week on the Home Screen | 30 |
| Category | Productivity (secondary: Utilities) | |
| Price | Free (no in-app purchases, no ads) | |
| Privacy Policy URL | Link to `PRIVACY.md` (or a GitHub Pages copy) once the repo is public | |
| Support URL | `https://github.com/usernamefourzerofour/WeekPeek/issues` | |
| Copyright | 2026 Erik Bouvin Poulsen | |

## Promotional text (170 characters)

> See your week at a glance, right on your Home Screen. Every widget has its own settings. Free, open source, no ads and no tracking.

## Keywords (100 characters, comma-separated, no spaces)

```
calendar,week,agenda,planner,schedule,events,week view,week number,standby,overview,upcoming,days
```

Avoid other companies' app names (Outlook, Google, Fantastical) in keywords; Apple rejects that. They may be mentioned in the description.

## Description (4000 characters)

> WeekPeek shows your upcoming events in a clean, compact grid on your Home Screen. Tap a day to open it in your calendar app.
>
> WORKS WITH THE CALENDARS ON YOUR IPHONE
> WeekPeek shows the calendars in your iPhone's Calendar: iCloud, Google, Microsoft Exchange and more. Using Google Calendar or Outlook? Add your account in Settings › Apps › Calendar › Calendar Accounts. Events that live only inside the Google Calendar or Outlook app can't be shown.
>
> EVERY WIDGET IS YOURS TO SHAPE
> Each widget has its own settings under Edit Widget, so you can have a two-day close-up next to a two-week overview.
>
> • Small, medium and large widgets, also in StandBy
> • 1 to 14 days, in 1 to 7 columns
> • Start on today or on a fixed weekday
> • Lines per event: Auto fits as much as possible and shows "+N more" when a day is full
> • Text size from 8 to 20 pt
> • Optional start times and week numbers
> • Calendar colors, a color stripe or a single color
> • Days off shown with a soft background
> • All-day events shown, grouped at the top or hidden
> • Hide declined and finished events
> • Opens Apple Calendar, Google Calendar, Microsoft Outlook or Fantastical
> • 38 languages, including right-to-left
>
> PRIVATE BY DESIGN
> WeekPeek collects no data. It has no network code, no analytics and no tracking. Your events are read on your iPhone and never leave it.
>
> AN HONEST NOTE
> WeekPeek is a free hobby project, "vibe coded" with the help of AI (Claude by Anthropic) and maintained in spare time. It is not made to earn money: no ads, no in-app purchases, no subscriptions.
>
> The full source code is open under the MIT license on GitHub. Feedback, translation fixes and ideas are very welcome there.

## App Review notes

> WeekPeek is a Home Screen widget. It shows the calendars on the iPhone (EventKit). To test: open the app, allow calendar access, then add the WeekPeek widget from the Home Screen widget gallery. Long-press the widget and choose Edit Widget to see all settings. No account or demo login is needed. The app makes no network requests.

## App Privacy ("nutrition label")

**Data Not Collected.** Matches `Shared/PrivacyInfo.xcprivacy` (no tracking, no collected data types; only the required UserDefaults reason `CA92.1`).

## Age rating (suggested answers)

All content questions: **None / No** (no violence, mature themes, gambling, user-generated content, web access, chat, advertising or in-app purchases). Expected result: **4+**. Erik confirms the answers in App Store Connect; nothing is submitted on his behalf.

## EU trader status (Digital Services Act)

Decision: **non-trader**. The app is free with no ads, in-app purchases or subscriptions, so Erik does not act as a trader.

- Non-traders' address, phone and email are not shown on the App Store page.
- The developer name shown on the App Store is still Erik's legal name (individual developer account).
- Linking to donations or other income later could change this; check first.

## Screenshots

Ready in `docs/appstore/` (6.9" iPhone, 1320 × 2868, sample events only). Headline on a pastel background above a Home Screen: a soft gradient wallpaper, real app icons and dock, and the widgets from the render tests with their "WeekPeek" label.

1. `1-week.png`: Your week at a glance (medium widget, small widget beside app icons)
2. `2-styles.png`: Light, dark or tinted
3. `3-yours.png`: Make every widget your own (stripe, 10 days, big text)
4. `4-languages.png`: Speaks your language (Danish)
5. `5-private.png`: Private by design (small widget beside app icons, dark widget)

`Tests/SampleCalendarSeeder.swift` seeds the Simulator's calendar with the same sample events, for real Home Screen screenshots.
