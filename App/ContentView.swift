import SwiftUI
import EventKit
import WidgetKit

@MainActor
final class CalendarAccess: ObservableObject {
    let store = EKEventStore()
    @Published var status = EKEventStore.authorizationStatus(for: .event)
    /// Synced calendar accounts on the iPhone (iCloud, Google, Exchange …), by name.
    @Published var accounts: [String] = []
    @Published var hasUpcomingEvents = true

    func refresh() {
        status = EKEventStore.authorizationStatus(for: .event)
        if status == .fullAccess {
            store.refreshSourcesIfNecessary()
            // Local, subscribed (holidays) and birthday calendars are not accounts the user set up.
            let synced: Set<EKSourceType> = [.calDAV, .exchange, .mobileMe]
            let calendars = store.calendars(for: .event).filter { synced.contains($0.source.sourceType) }
            accounts = Array(Set(calendars.map(\.source.title))).sorted()
            let start = Calendar.current.startOfDay(for: .now)
            let end = Calendar.current.date(byAdding: .day, value: 14, to: start)!
            hasUpcomingEvents = !store.events(matching: store.predicateForEvents(withStart: start, end: end, calendars: nil)).isEmpty
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    #if DEBUG
    /// Simulator testing only: launch with `-SeedDemoEvents YES` to add sample events.
    func seedDemoEventsIfRequested() {
        guard UserDefaults.standard.bool(forKey: "SeedDemoEvents"),
              EKEventStore.authorizationStatus(for: .event) == .fullAccess,
              let target = store.defaultCalendarForNewEvents else { return }
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 14, to: start)!
        let existing = store.events(matching: store.predicateForEvents(withStart: start, end: end, calendars: nil))
        guard existing.isEmpty else { return }
        for e in WeekModel.sample(now: .now).events {
            let ev = EKEvent(eventStore: store)
            ev.title = e.title
            ev.startDate = e.start
            ev.endDate = e.end
            ev.isAllDay = e.isAllDay
            ev.calendar = target
            try? store.save(ev, span: .thisEvent, commit: false)
        }
        try? store.commit()
    }
    #endif

    func request() async {
        _ = try? await store.requestFullAccessToEvents()
        refresh()
    }
}

struct ContentView: View {
    @EnvironmentObject private var router: Router
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var access = CalendarAccess()

    private var settingsURL: URL { URL(string: UIApplication.openSettingsURLString)! }
    /// Texts that name the device have an iPhone and an iPad version.
    private let isPad = UIDevice.current.userInterfaceIdiom == .pad

    var body: some View {
        NavigationStack {
            Form {
                if let msg = router.message {
                    Section {
                        Label(msg, systemImage: "arrow.up.forward.app")
                        if let app = router.failedApp {
                            Link("Get \(app.displayName) on the App Store", destination: app.appStoreURL)
                        }
                    }
                }

                Section("Calendar access") {
                    switch access.status {
                    case .fullAccess:
                        Label("Access granted", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    case .notDetermined:
                        Button("Allow calendar access") { Task { await access.request() } }
                    default:
                        Label("No full access. Turn it on in Settings › Apps › WeekPeek.",
                              systemImage: "exclamationmark.triangle")
                        Button("Open Settings") { router.openRaw(settingsURL) }
                    }
                }

                if access.status == .fullAccess {
                    Section("Your calendars") {
                        if access.accounts.isEmpty {
                            Label(isPad ? "No calendar accounts found on your iPad" : "No calendar accounts found on your iPhone",
                                  systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        } else {
                            let list = access.accounts.formatted(.list(type: .and))
                            Text(isPad ? "Found on your iPad: \(list)" : "Found on your iPhone: \(list)")
                            if !access.hasUpcomingEvents {
                                Label("No events in the next two weeks", systemImage: "calendar.badge.exclamationmark")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                // WeekPeek reads only the iPhone's own calendar database (EventKit), never the network.
                Section("Using Google Calendar or Outlook?") {
                    Text(isPad
                         ? "WeekPeek shows only the calendars on your iPad. Events that live only in the Google Calendar or Outlook app are not included. Add your account to your iPad to see them:"
                         : "WeekPeek shows only the calendars on your iPhone. Events that live only in the Google Calendar or Outlook app are not included. Add your account to your iPhone to see them:")
                    Text("Settings › Apps › Calendar › Calendar Accounts › Add Account")
                        .fontWeight(.semibold)
                    Text(isPad
                         ? "Choose Google or Microsoft Exchange, sign in and turn on Calendars. Your events stay on your iPad."
                         : "Choose Google or Microsoft Exchange, sign in and turn on Calendars. Your events stay on your iPhone.")
                }
                .font(.callout)

                Section {
                    Button {
                        router.openRaw(settingsURL)
                    } label: {
                        Label("Change language", systemImage: "globe")
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text(isPad
                         ? "WeekPeek follows your iPad's language. You can choose another language for WeekPeek under Language in Settings. It applies to the app and all widgets."
                         : "WeekPeek follows your iPhone's language. You can choose another language for WeekPeek under Language in Settings. It applies to the app and all widgets.")
                }

                Section("How to use the widget") {
                    Text("Touch and hold the Home Screen › Edit › Add Widget › WeekPeek. Choose small, medium or large.")
                    Text("Touch and hold the widget › Edit Widget to choose days, columns, text size, colors and more.")
                    Text("Each widget opens its own calendar app. Choose it at the top of Edit Widget under Open in: Apple Calendar, Google Calendar, Microsoft Outlook or Fantastical.")
                    Text("Tap a day to open your calendar app. Apple Calendar and Fantastical open on the day you tap. Google Calendar and Outlook just open the app. The small widget shows several days, but you can't choose a single day on it: a tap opens your calendar app on today's date.")
                }
                .font(.callout)
            }
            .navigationTitle("WeekPeek")
        }
        .task {
            #if DEBUG
            access.seedDemoEventsIfRequested()
            #endif
            access.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in access.refresh() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { access.refresh() } }
    }
}
