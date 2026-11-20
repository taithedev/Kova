import SwiftUI

@main struct KovaApp: App {
    @StateObject private var session = SessionStore()
    @AppStorage("kova.appearance") private var appearance = "dark"
    @AppStorage("kova.accent") private var accent = "classic"

    private var preferredMode: ColorScheme? {
        if appearance == "system" { return nil }
        return appearance == "light" ? .light : .dark
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(session)
                .preferredColorScheme(preferredMode)
                .tint(KovaTheme.accent)
                .task { await session.restore() }
        }
    }
}
