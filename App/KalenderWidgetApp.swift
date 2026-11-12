import SwiftUI
import UIKit

@main
struct KalenderWidgetApp: App {
    @StateObject private var router = Router()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .onOpenURL { router.handle($0) }
        }
    }
}

/// Receives taps from the widget and forwards the user to the chosen calendar app.
@MainActor
final class Router: ObservableObject {
    @Published var message: String?
    @Published var failedApp: CalendarApp?

    func handle(_ url: URL) {
        guard let link = DeepLink.parse(url) else { return }
        open(link.app, date: link.date)
    }

    func open(_ app: CalendarApp, date: Date?) {
        failedApp = nil
        // The chosen app is not installed (its scheme is in LSApplicationQueriesSchemes):
        // open Apple Calendar on the same day instead and explain when the user comes back.
        if app != .apple, !UIApplication.shared.canOpenURL(app.rootURL) {
            failedApp = app
            message = String(localized: "\(app.displayName) is not installed, so Apple Calendar opened instead. Choose another app under Edit Widget › Open in.")
            UIApplication.shared.open(CalendarApp.apple.targetURL(for: date))
            return
        }
        message = String(localized: "Opening \(app.displayName)…")
        UIApplication.shared.open(app.targetURL(for: date)) { [weak self] ok in
            guard let self else { return }
            if ok { self.message = nil; return }
            // Fallback: open the app without a date.
            UIApplication.shared.open(app.rootURL) { ok2 in
                if ok2 {
                    self.message = nil
                } else {
                    self.message = String(localized: "\(app.displayName) could not be opened. Is the app installed?")
                    self.failedApp = app
                }
            }
        }
    }

    func openRaw(_ url: URL) {
        UIApplication.shared.open(url) { [weak self] ok in
            self?.message = ok ? nil : String(localized: "The link could not be opened.")
        }
    }
}
