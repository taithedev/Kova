import SwiftUI
struct WelcomeView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var showAuth = false
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 13) {
                        KovaMark(size: 38)
                        Text("KOVA").font(.system(size: 23, weight: .black)).tracking(-1)
                        Spacer()
                        Text("01 /").font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(KovaTheme.muted)
                    }
                    .padding(.top, 22)
                    Spacer()
                    Text("THIS IS\nYOUR\nSPACE.")
                        .font(.system(size: min(geo.size.width * 0.153, 69), weight: .black))
                        .tracking(-3.8)
                        .lineSpacing(-5)
                        .fixedSize(horizontal: false, vertical: true)
                    Rectangle().fill(.white).frame(width: 54, height: 3).padding(.top, 28)
                    Text("Watch what moves you.\nCreate what matters.")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(KovaTheme.muted)
                        .lineSpacing(4)
                        .padding(.top, 22)
                    Spacer()
                    GradientButton("Enter Kova", icon: "arrow.up.right") { showAuth = true }
                    Button("Explore without an account") { session.preview() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 54)
                    Text("Social accounts are 13+. Under-13 access isn't enabled.")
                        .font(.system(size: 11))
                        .foregroundStyle(KovaTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                    Spacer().frame(height: 25)
                }
                .padding(.horizontal, 26)
            }
        }
        .sheet(isPresented: $showAuth) { AuthView().presentationDragIndicator(.visible) }
    }
}
