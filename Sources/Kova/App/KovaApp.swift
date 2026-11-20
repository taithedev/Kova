import SwiftUI

@main struct KovaApp: App {
    @StateObject private var session = SessionStore()
    @AppStorage("kova.appearance") private var appearance = "dark"

    private var preferredMode: ColorScheme? {
        if appearance == "system" { return nil }
        return appearance == "light" ? .light : .dark
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(session)
                .preferredColorScheme(preferredMode)
                .tint(KovaTheme.foreground)
                .task { await session.restore() }
        }
    }
}
