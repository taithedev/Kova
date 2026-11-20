import SwiftUI
struct AppRouter: View {
    @EnvironmentObject private var session: SessionStore
    var body: some View {
        Group {
            if session.user != nil || session.isPreviewing {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
        .animation(.smooth(duration: 0.25), value: session.isPreviewing)
        .animation(.smooth(duration: 0.25), value: session.user?.id)
    }
}
