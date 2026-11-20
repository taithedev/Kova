import SwiftUI

struct MainTabView: View {
    @State private var selected = 0

    var body: some View {
        TabView(selection: $selected) {
            FeedView().tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            ExploreView().tabItem { Label("Discover", systemImage: "safari") }.tag(1)
            UploadView().tabItem { Label("Create", systemImage: "plus") }.tag(2)
            InboxView().tabItem { Label("Inbox", systemImage: "tray") }.tag(3)
            MyProfileView().tabItem { Label("Profile", systemImage: "person.crop.circle") }.tag(4)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 6) {
                    controls
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 30))
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 5)
            } else {
                controls
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .kovaGlass(radius: 27)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 5)
            }
        }
        .tint(KovaTheme.foreground)
    }

    private var controls: some View {
        HStack(spacing: 1) {
            tab(0, "house", "Home")
            tab(1, "safari", "Discover")
            Button {
                withAnimation(.snappy(duration: 0.25)) { selected = 2 }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(KovaTheme.inverted)
                    .frame(width: 52, height: 43)
                    .background(KovaTheme.foreground, in: RoundedRectangle(cornerRadius: 14))
                    .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("Create a video")
            tab(3, "tray", "Inbox")
            tab(4, "person.crop.circle", "Profile")
        }
    }

    private func tab(_ index: Int, _ symbol: String, _ title: String) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { selected = index }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: selected == index ? filled(symbol) : symbol)
                    .font(.system(size: 21, weight: selected == index ? .bold : .medium))
                    .frame(height: 25)
                Text(title)
                    .font(.system(size: 10, weight: selected == index ? .bold : .medium))
            }
            .foregroundStyle(selected == index ? KovaTheme.foreground : KovaTheme.muted)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected == index ? [.isSelected] : [])
    }

    private func filled(_ symbol: String) -> String {
        if symbol == "safari" { return "safari.fill" }
        if symbol == "person.crop.circle" { return "person.crop.circle.fill" }
        return symbol + ".fill"
    }
}
