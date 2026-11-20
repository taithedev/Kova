import SwiftUI

struct MainTabView: View {
    @State private var selected = 0
    var body: some View {
        TabView(selection: $selected) {
            FeedView().tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            ExploreView().tabItem { Label("Discover", systemImage: "safari") }.tag(1)
            UploadView().tabItem { Label("Create", systemImage: "plus") }.tag(2)
            InboxView().tabItem { Label("Inbox", systemImage: "tray") }.tag(3)
            MyProfileView().tabItem { Label("Profile", systemImage: "person") }.tag(4)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Rectangle().fill(KovaTheme.border).frame(height: 0.5)
                HStack(spacing: 0) {
                    tab(0, "house", "Home")
                    tab(1, "magnifyingglass", "Explore")
                    Button { selected = 2 } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 52, height: 43)
                            .background(.white, in: RoundedRectangle(cornerRadius: 12))
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityLabel("Create video")
                    tab(3, "tray", "Inbox")
                    tab(4, "person.crop.circle", "Profile")
                }
                .padding(.horizontal, 12)
                .padding(.top, 11)
                .padding(.bottom, 6)
            }
            .background(.black)
        }
        .tint(.white)
    }
    private func tab(_ index: Int, _ symbol: String, _ name: String) -> some View {
        Button { selected = index } label: {
            VStack(spacing: 5) {
                Image(systemName: selected == index ? symbol + ".fill" : symbol)
                    .font(.system(size: 21, weight: selected == index ? .semibold : .regular))
                    .frame(height: 24)
                Text(name).font(.system(size: 10, weight: selected == index ? .bold : .medium))
            }
            .foregroundStyle(selected == index ? Color.white : KovaTheme.muted)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityAddTraits(selected == index ? [.isSelected] : [])
    }
}
