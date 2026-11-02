import SwiftUI
import EventKit
import WidgetKit

@MainActor
final class CalendarAccess: ObservableObject {
    let store = EKEventStore()
    @Published var status = EKEventStore.authorizationStatus(for: .event)

    func refresh() {
        status = EKEventStore.authorizationStatus(for: .event)
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

                Section {
                    Button {
                        router.openRaw(settingsURL)
                    } label: {
                        Label("Change language", systemImage: "globe")
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text("WeekPeek follows your iPhone's language. You can choose another language for WeekPeek under Language in Settings. It applies to the app and all widgets.")
                }

                Section("How to use the widget") {
                    Text("Touch and hold the Home Screen › Edit › Add Widget › WeekPeek. Choose small, medium or large.")
                    Text("Touch and hold the widget › Edit Widget to choose days, columns, text size, colors and more.")
                    Text("Tap a day to open your calendar app on that day.")
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
