import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var showAuth = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                KovaTheme.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 11) {
                        KovaMark(size: 43)
                        Text("KOVA")
                            .font(.system(size: 21, weight: .black))
                            .tracking(-0.8)
                            .foregroundStyle(KovaTheme.foreground)
                        Spacer()
                        Text("FOR YOU / BY YOU")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(KovaTheme.muted)
                    }
                    .padding(.top, 18)
                    Spacer()
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 29)
                            .fill(KovaTheme.banner("glacier"))
                        Circle()
                            .stroke(.white.opacity(0.27), lineWidth: 1)
                            .frame(width: 270, height: 270)
                            .offset(x: 175, y: -120)
                        Circle()
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                            .frame(width: 190, height: 190)
                            .offset(x: 55, y: 65)
                        VStack(alignment: .leading, spacing: 9) {
                            Text("YOUR WORLD.\nYOUR VIDEOS.")
                                .font(.system(size: min(geometry.size.width * 0.082, 38), weight: .black))
                                .tracking(-1.6)
                                .foregroundStyle(.white)
                            Text("Share what matters.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(25)
                    }
                    .frame(height: max(200, min(265, geometry.size.height * 0.33)))
                    .clipped()
                    .padding(.bottom, 32)
                    Text("A space that's\nactually yours.")
                        .font(.system(size: min(geometry.size.width * 0.105, 47), weight: .heavy))
                        .tracking(-1.9)
                        .foregroundStyle(KovaTheme.foreground)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Watch, create and connect with real people.")
                        .font(.system(size: 15))
                        .foregroundStyle(KovaTheme.muted)
                        .padding(.top, 15)
                    Spacer(minLength: 18)
                    GradientButton("Get started", icon: "arrow.right") { showAuth = true }
                    Button("Explore first") { session.preview() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(KovaTheme.foreground)
                        .frame(maxWidth: .infinity, minHeight: 49)
                    Text("Ages 13+ · Profiles start private · No automated feeds")
                        .font(.system(size: 11))
                        .foregroundStyle(KovaTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 10)
                }
                .padding(.horizontal, 25)
            }
        }
        .sheet(isPresented: $showAuth) {
            AuthView().presentationDragIndicator(.visible)
        }
    }
}
