import SwiftUI

@main struct KovaApp: App {
    @StateObject private var session = SessionStore()
    @StateObject private var support = KovaSupportStore()
    @StateObject private var updates = KovaUpdateChecker()
    @StateObject private var remix = KovaRemixCoordinator()
    @Environment(\.scenePhase) private var scenePhase
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
                .environmentObject(support)
                .environmentObject(updates)
                .environmentObject(remix)
                .preferredColorScheme(preferredMode)
                .tint(KovaTheme.accent)
                .task {
                    await session.restore()
                    support.bind(account: session.user?.id)
                    await updates.check()
                }
                .onChange(of: session.user?.id) { _, currentAccount in
                    support.bind(account: currentAccount)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await session.refreshIfNeeded() }
                        Task { await updates.check() }
                    }
                }
        }
    }
}
