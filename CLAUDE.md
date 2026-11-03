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
| `Widget/WeekWidget.swift` | Widget bundle, sizes (small, medium, large) and timeline provider. |
| `Shared/` | Used by both targets: models, options (`AppEnum`s), layout engine (`DayLayout`, `LineFit`), widget view, intent, event loading, deep links, translations. |
| `Tests/` | Unit tests plus render tests that write PNG previews. |
| `tools/make_icon.swift` | Draws the app icon (macOS only). |

Names: the app is **WeekPeek** (App Store: "WeekPeek: Calendar Widget"), but targets, scheme and project are still `KalenderWidget`. Bundle IDs: `dk.erik.kalenderwidget` and `dk.erik.kalenderwidget.widget`. Deployment target iOS 26, iPhone only.

## How the widget works

- Every setting is a parameter of `WeekWidgetIntent` (per widget, "Edit Widget"). The app has no settings of its own on purpose: keep the app simple and the widget powerful.
- `WeekSettings.grid(for:)` turns days/columns ("Auto" = per size) into a grid; rows are derived.
- `LineFit` decides lines per event: Auto allows up to 3, shrinks the longest titles first, then shows "+N more". Text is measured with UIKit (`boundingRect`) plus a safety margin, because SwiftUI lays out slightly wider. A word that cannot fit is truncated on one line rather than wrapped mid-word.
- Tapping a day opens the app through `kalenderwidget://open?app=…&date=…`; `Router` forwards to the chosen calendar app. Only Apple Calendar and Fantastical support a date; Google Calendar and Outlook (`ms-outlook://events`, undocumented; plain `ms-outlook://` only opens the last tab) open on today.
- A widget cannot check which apps are installed, so the app list is static.
- Events come only from the iPhone's calendar database (EventKit): accounts added under Settings › Apps › Calendar › Calendar Accounts. Events that live only in the Google Calendar or Outlook app are invisible. Erik decided to keep it that way (no network, no data collection); the app lists the accounts it finds and explains how to add one, with a warning when there are none or no events in the next two weeks.

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

1. Bump `CURRENT_PROJECT_VERSION` in `project.yml` (build 7 is the latest uploaded; next is 8). Info.plists read the version from there.
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

- Build 6 (1.0) is on TestFlight but declares iPad support (XcodeGen sets `TARGETED_DEVICE_FAMILY` "1,2" per target), so Apple asks for iPad screenshots. Build 7 (`bld_ZW2u522DvkD2K9IsJ1Kfd`, uploaded 3 Nov) sets "1" on both targets and is the build to submit. Repository is public; PR #1 is merged.
- App Store Connect (version 1.0, en-US) is filled in via NoMac: listing texts from `docs/app-store.md`, URLs, category Productivity, free, copyright "2026 Erik Bouvin Poulsen", review contact, age rating (all none). Screenshots from `docs/appstore/` are in ASC.
- Erik has done App Privacy ("Data Not Collected") and DSA "not a trader" (account-wide, also covers "Rene hænder"). "Sign-in required" is unchecked.
- Content rights ("No") and App Privacy are published. Still open: `publish` preview with build `bld_ZW2u522DvkD2K9IsJ1Kfd`, show Erik, submit on his yes. "Automatically release" is selected.
- NoMac's screenshot upload of 5 images takes 10–15 minutes ("replacing" means still working); `publish` answers `apple_edit_in_progress` until it is done.

NoMac lessons:
- `upload_screenshots` only accepts `create_mac_link` download links (or base64); GitHub links are refused. A 1-minute Mac that curls the PNGs from GitHub is enough; the links outlive the Mac.
- The age rating needs `socialMedia` besides the usual keys.
- `review_contact.demo_account_required: false` did not clear "Sign-in required" in ASC; check it by hand.

## Commits

Commit messages in English, imperative mood. End them with:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```
