import SwiftUI

struct AppRouter: View {
    @EnvironmentObject private var session: SessionStore
    var body: some View {
        Group {
            if session.isRestoring {
                ZStack {
                    KovaTheme.background.ignoresSafeArea()
                    VStack(spacing: 20) {
                        KovaMark(size: 72)
                        ProgressView().tint(.white)
                    }
                }
            } else if session.user != nil || session.isPreviewing {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
        .animation(.smooth(duration: 0.25), value: session.isPreviewing)
        .animation(.smooth(duration: 0.25), value: session.user?.id)
    }
}
