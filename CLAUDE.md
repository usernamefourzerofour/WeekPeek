# CLAUDE.md

Guidance for Claude working on WeekPeek, an iOS Home Screen calendar widget (Swift, SwiftUI, WidgetKit, App Intents).

## Working with Erik

- Talk to Erik in Danish unless he writes in English. Code, comments, commit messages and the README stay in English.
- Keep answers short and clear. Show only the files that changed.
- Say what an action costs before doing it (see NoMac below).
- Plan and write code first. Only start a Mac when there is something to build.
- Never put keys or passwords in the code or the repo. App Store credentials live at NoMac; use `request_secret` if something is ever needed.
- After every build: summarise errors and warnings briefly and suggest the next step.

## Project layout

| Path | Contents |
| --- | --- |
| `project.yml` | XcodeGen spec. The `.xcodeproj` and both `Info.plist` files are generated from it and are git-ignored. |
| `App/` | The app: calendar access, "Change language" button (opens the app's Settings page), short guide. |
| `Widget/WeekWidget.swift` | Widget bundle, sizes (small, medium, large, extra large on iPad) and timeline provider. |
| `Shared/` | Used by both targets: models, options (`AppEnum`s), layout engine (`DayLayout`, `LineFit`), widget view, intent, event loading, deep links, translations. |
| `Tests/` | Unit tests plus render tests that write PNG previews. |
| `tools/make_icon.swift` | Draws the app icon (macOS only). |

Names: the app is **WeekPeek** (App Store: "WeekPeek: Calendar Widget"), but targets, scheme and project are still `KalenderWidget`. Bundle IDs: `dk.erik.kalenderwidget` and `dk.erik.kalenderwidget.widget`. Deployment target iOS 26. iPhone and iPad from 1.2 (`TARGETED_DEVICE_FAMILY` "1,2" set on each target; 1.0 and 1.1 were iPhone only). On iPad the widget also offers extra large (`WidgetSize.extraLarge`, 14 days in 7 columns by default). App texts that name the device have an iPad twin key ("…your iPad…"), chosen by `isPad` in `ContentView`.

## How the widget works

- Every setting is a parameter of `WeekWidgetIntent` (per widget, "Edit Widget"). The app has no settings of its own on purpose: keep the app simple and the widget powerful.
- `WeekSettings.grid(for:)` turns days/columns ("Auto" = per size) into a grid; rows are derived.
- `LineFit` decides lines per event: Auto allows up to 3, shrinks the longest titles first, then shows "+N more". Text is measured with UIKit (`boundingRect`) plus a safety margin, because SwiftUI lays out slightly wider. A word that cannot fit is truncated on one line rather than wrapped mid-word.
- Tapping a day opens the app through `kalenderwidget://open?app=…&date=…`; `Router` forwards to the chosen calendar app. Only Apple Calendar and Fantastical support a date; Google Calendar and Outlook (`ms-outlook://events`, undocumented; plain `ms-outlook://` only opens the last tab) open on today.
- A widget cannot check which apps are installed, so the app list is static. From 1.3 "Open in" defaults to Apple Calendar (was Google Calendar), and the app (`Router`) checks `canOpenURL` first: if the chosen app is not installed it opens Apple Calendar on the tapped day and explains this, with an App Store link, when the user returns.
- Events come only from the iPhone's calendar database (EventKit): accounts added under Settings › Apps › Calendar › Calendar Accounts. Events that live only in the Google Calendar or Outlook app are invisible. Erik decided to keep it that way (no network, no data collection; on 7 Nov he also rejected direct Google Calendar / Microsoft Graph integration: OAuth, Google verification and network code would cost the clean, private approach); the app lists the accounts it finds and explains how to add one, with a warning when there are none or no events in the next two weeks.

## Localisation

- English is the development language. All user-facing strings are English keys in `Shared/Localizable.xcstrings` (and `App/InfoPlist.xcstrings`, `Widget/InfoPlist.xcstrings` for the calendar permission text).
- 37 translations plus English (see `CFBundleLocalizations` in `project.yml`). When you add or change a string, add translations for every language in the catalog, keep format specifiers (`%lld`, `%@`, `${app}`) identical, and render-test it.
- Right-to-left (ar, he): wrap number ranges in Unicode isolates (`⁦…⁩`), otherwise "45–46" displays as "46–45".
- Erik deliberately dropped languages Claude is not confident in (Indian languages other than Hindi, Urdu, Kazakh, Tatar). Do not add them back without asking.

## Building and testing with NoMac

The cloud environment is Linux, so all Xcode work runs on a NoMac cloud Mac via the NoMac MCP tools. Price: $0.90 per hour, billed per minute.

Rules:
- Ask Erik before starting a Mac: say what it is for and roughly what it costs.
- The clock runs while the Mac is ready, also between commands. Batch steps and stop the Mac as soon as you are done; always stop it, also after a failure.
- Only one Mac at a time. Always pass a `request_key` to `start_mac` and `exec_mac`. Run shell commands as `["/bin/bash","-lc","..."]`.
- Stopping deletes everything except `~/drive`. The project lives in `~/drive/src/KalenderWidget` (derived data in `~/drive/dd`, logs in `~/drive/src/logs`, renders in `~/drive/src/renders`). Fetch anything else before stopping.
- If a build hangs, use `cancel_mac_job`.

Getting code onto the Mac (the Mac cannot clone this private repo):
1. Zip the repo working tree (without `.git`).
2. `create_mac_link` with `direction: upload`, `path: ~/drive/src/KalenderWidget`, `extract: zip`.
3. Run its `upload_command` with `curl` from the cloud shell (needs network access to `nomac.app` and `*.r2.cloudflarestorage.com`).
For results, use `read_mac_file` (images come back viewable) or `create_mac_link` with `direction: download`.

Typical build and test (simulator id is cached in `~/drive/src/logs/sim.txt`):

```sh
cd ~/drive/src/KalenderWidget && xcodegen generate
SIM=$(cat ~/drive/src/logs/sim.txt); xcrun simctl boot $SIM; xcrun simctl bootstatus $SIM -b
xcodebuild test -project KalenderWidget.xcodeproj -scheme KalenderWidget \
  -destination "id=$SIM" -derivedDataPath ~/drive/dd CODE_SIGN_IDENTITY=-
```

- Boot the simulator before testing; the first render after a cold boot can fail with a zlib/PNG error. Re-run only the render tests if that happens.
- `xcodebuild` can hang after the tests have finished. Check the log and cancel the job instead of waiting.
- macOS has no `timeout` command.
- Look at the render output yourself (`renders/r3` per variant, `renders/lang/sheet-*.png` per language) before uploading. Visual checks have caught real bugs: mid-word wrapping, week labels pushing day names out, reversed RTL ranges.

## Releasing to TestFlight

1. Bump `CURRENT_PROJECT_VERSION` in `project.yml` (build 11 is the latest uploaded; next is 12). Info.plists read the version from there.
2. Archive and export with the signing files NoMac installs on every Mac:

```sh
xcodebuild archive -project KalenderWidget.xcodeproj -scheme KalenderWidget -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/KalenderWidget.xcarchive \
  -xcconfig "$HOME/.nomac/signing/BYNRN8J29U.xcconfig"
xcodebuild -exportArchive -archivePath build/KalenderWidget.xcarchive -exportPath build/export \
  -exportOptionsPlist "$HOME/.nomac/signing/BYNRN8J29U.ExportOptions.plist"
```

3. `send_to_testflight` with the absolute path `/Users/agent/drive/src/KalenderWidget/build/export/KalenderWidget.ipa` and short "What to Test" notes in English. Stop the Mac once Apple has the build; processing needs no Mac. NoMac project id: `prj_IRXZqUSLAVZvkO1M4C7DI`.
4. Apple rejects builds without all four interface orientations (`ITMS-90474`); they are set in `project.yml`. Encryption export compliance is answered in `Info.plist` (`ITSAppUsesNonExemptEncryption: false`). The app collects no data (`Shared/PrivacyInfo.xcprivacy`).

## App Store status (3 Nov 2026)

- Version 1.0, build 7 (`bld_ZW2u522DvkD2K9IsJ1Kfd`, iPhone only) was submitted to App Review on 3 Nov (submission `fd5b017e-a164-4773-b536-d0eb780aba93`), released automatically after approval. On 3 Nov Apple answered "Guideline 2.1 – Information Needed" (screen recording from a device plus purpose, setup, external services, regions, regulation); on 4 Nov Erik added a recording and notes in ASC and resubmitted build 7. Approved and READY_FOR_SALE on 6 Nov. Country availability had never been set (the app showed "not available in your country"); Erik set all 175 countries on 6 Nov ("Processing to Available", up to 24 h). Check with `https://itunes.apple.com/lookup?id=6829527873&country=dk`. Check with `get_review`; reviewer messages are only in App Store Connect.
- Build 6 declared iPad support (XcodeGen sets `TARGETED_DEVICE_FAMILY` "1,2" per target unless each target sets "1"), so Apple asked for iPad screenshots.
- Next: version 1.1, build 8 (`MARKETING_VERSION` 1.1 in `project.yml`): the "Your calendars" and "Using Google Calendar or Outlook?" help in the app. Also a corrected guide line: only Apple Calendar and Fantastical open on the tapped day; Google Calendar, Outlook and the small widget open on today. Build 8 (`bld_sJxJxlTN4MvSTOQmJRVCM`) was tested by Erik on his iPhone and submitted to App Review on 7 Nov (submission `ca1ef5a3-acdc-4ea9-82ac-605ded9771a7`) with the new description and "What's New". Release is MANUAL (NoMac default for new versions): after approval Erik taps "Release This Version" in ASC unless he switched it to automatic.
- Version 1.2 (build 9, `bld_PccTsLz1MSuiJPZuvvVkt`, iPhone and iPad) was sent to TestFlight on 6 Nov after all tests passed and a check in the iPad Pro 13" Simulator (portrait and landscape). iPad App Store screenshots are in `docs/appstore/ipad-*.png` (2048 × 2732, as display type APP_IPAD_PRO_3GEN_129 requires). Submit only after 1.1 is approved and released.
- Build 11 (`bld_qx2rZYxXpwyQotBN4nQiM`, 1.2, 7 Nov) adds more space below the week label and is the build to submit as 1.2. Build 10 (`bld_B2wJ5qtG7tWr8X9mfdCKs`) went to the external group "External testing" (group `9817d506-aa22-421a-9cba-b877c92517c1`) and Beta App Review on 7 Nov; TestFlight test information is filled in via NoMac. Build 10: text size 6–20 pt. iOS let Erik enter a value below the intent's `inclusiveRange` (8–20) and then rejected the configuration, showing only the redacted placeholder (7 Nov). The parameter is now a stepper (`controlStyle: .stepper`, range 6–20) so nothing can be typed; `WeekSettings.clampedFontSize` still clamps to 6–20. Check on a device that Edit Widget shows – and + buttons.
- 1.1 was approved on 7 Nov and is READY_FOR_SALE. Version 1.2 exists in ASC (8 Nov) with the iPad description and "What's New"; iPad screenshots are uploaded. Submitted to App Review on 8 Nov with build 11 (submission `bbfcd7ec-a409-4961-a71b-b9e36a278801`), release AFTER_APPROVAL (automatic, set with `update_store` appStoreVersions_updateInstance).
- Version 1.3 (build 12) is written but not built: Apple Calendar as default and fallback (a colleague without Google Calendar only got "install Google Calendar") "Open in" is now the first setting in Edit Widget (`Summary { \.$app; … }` without a sentence; check that it compiles and shows at the top), and the app guide has a line about it in all 37 languages.
- App Store Connect is filled in (texts, URLs, Productivity, free, copyright "2026 Erik Bouvin Poulsen", review contact, age rating 4+, content rights "No", App Privacy "Data Not Collected", DSA non-trader for the whole account). Screenshots are from `docs/appstore/`.
- Metadata of a version cannot be changed through NoMac once it is READY_FOR_REVIEW or later; promotional text can be changed on a live version without review.

NoMac lessons:
- `upload_screenshots` only accepts `create_mac_link` download links (or base64); GitHub links are refused. A 1-minute Mac that curls the PNGs from GitHub is enough; the links outlive the Mac.
- The age rating needs `socialMedia` besides the usual keys.
- iPad screenshots: NoMac uploads to APP_IPAD_PRO_3GEN_129, which takes only 2048 × 2732 (not the 2064 × 2752 of newer iPads). Use commit-SHA raw.githubusercontent.com URLs on the Mac to avoid GitHub's raw cache right after a push.
- `review_contact.demo_account_required: false` did not clear "Sign-in required" in ASC; check it by hand.

## Commits

Commit messages in English, imperative mood. End them with:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```
