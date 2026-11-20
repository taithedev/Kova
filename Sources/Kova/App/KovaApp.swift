import SwiftUI
@main struct KovaApp: App {
    @StateObject private var session = SessionStore()
    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(session)
                .preferredColorScheme(.dark)
                .tint(KovaTheme.lavender)
                .task { await session.restore() }
        }
    }
}
