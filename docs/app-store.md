# App Store listing (draft)

Working notes for the App Store Connect listing. English is the primary language; other languages can reuse the English text or be translated later.

## Basics

| Field | Value | Limit |
| --- | --- | --- |
| Name | WeekPeek: Calendar Widget | 30 |
| Subtitle | Your week on the Home Screen | 30 |
| Category | Productivity (secondary: Utilities) | |
| Price | To be decided by Erik (see "Price" below) | |
| Privacy Policy URL | Link to `PRIVACY.md` (or a GitHub Pages copy) once the repo is public | |
| Support URL | `https://github.com/usernamefourzerofour/WeekPeek/issues` | |
| Copyright | 2026 Erik Bouvin Poulsen | |

## Promotional text (170 characters)

> See your week at a glance, right on your Home Screen. Every widget has its own settings. Open source: buy it to support the project, or build it yourself for free.

## Keywords (100 characters, comma-separated, no spaces)

```
calendar,week,agenda,planner,schedule,events,week view,week number,standby,overview,upcoming,days
```

Avoid other companies' app names (Outlook, Google, Fantastical) in keywords; Apple rejects that. They may be mentioned in the description.

## Description (4000 characters)

> WeekPeek shows your upcoming events in a clean, compact grid on your Home Screen. Tap a day to open it in your calendar app.
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
> WeekPeek is a hobby project, "vibe coded" with the help of AI (Claude by Anthropic) and maintained in spare time. It is not made to earn money. The price is a hope of covering part of the costs of building and publishing it.
>
> The full source code is open under the MIT license. If you would rather not pay, you are welcome to build it yourself from GitHub. Feedback, translation fixes and ideas are very welcome there too.

## App Review notes

> WeekPeek is a Home Screen widget. To test: open the app, allow calendar access, then add the WeekPeek widget from the Home Screen widget gallery. Long-press the widget and choose Edit Widget to see all settings. No account or demo login is needed. The app makes no network requests.

## App Privacy ("nutrition label")

**Data Not Collected.** Matches `Shared/PrivacyInfo.xcprivacy` (no tracking, no collected data types; only the required UserDefaults reason `CA92.1`).

## Age rating (suggested answers)

All content questions: **None / No** (no violence, mature themes, gambling, user-generated content, web access, chat, advertising or in-app purchases). Expected result: **4+**. Erik confirms the answers in App Store Connect; nothing is submitted on his behalf.

## EU trader status (Digital Services Act)

Apple requires every developer who distributes in the EU to declare **trader** or **non-trader**. A trader's address, phone and email are shown publicly on the App Store page.

- Charging money for an app can count as acting as a trader, even for a hobby project. Apple asks you to decide yourself and does not give legal advice.
- Options: declare as trader (contact details become public; a separate email and possibly a business address are a good idea), or make the app free and declare non-trader.
- This is Erik's decision. If unsure, Erhvervsstyrelsen or Forbrugerombudsmanden can advise.

## Price

The goal is to cover part of the costs (Apple Developer Program, cloud Mac time, AI tools), not to make a profit. Suggestion: the lowest price tier (around 9 kr / $0.99), one-time purchase, no in-app purchases or subscriptions. Remember that a paid app needs the Paid Apps Agreement and bank/tax details in App Store Connect.

## Screenshots

Still to do (open item 2). Required: 6.9" iPhone (1320 × 2868 or 2868 × 1320). Ideas: Home Screen with large widget; small + medium side by side; Edit Widget settings; StandBy; a right-to-left language.
