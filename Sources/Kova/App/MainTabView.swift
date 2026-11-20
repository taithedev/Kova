import SwiftUI

/// Only ONE navigation bar. SwiftUI's real system TabView provides native
/// iOS 26 Liquid Glass on supported devices; no manually drawn duplicate.
struct MainTabView: View {
    @AppStorage("kova.selectedTab") private var selected = 0

    var body: some View {
        TabView(selection: $selected) {
            FeedView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            ExploreView()
                .tabItem { Label("Discover", systemImage: "safari") }
                .tag(1)
            UploadView()
                .tabItem { Label("Create", systemImage: "plus.app.fill") }
                .tag(2)
            InboxView()
                .tabItem { Label("Inbox", systemImage: "tray.fill") }
                .tag(3)
            MyProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(4)
        }
        .tint(KovaTheme.accent)
        .animation(.easeOut(duration: 0.2), value: selected)
    }
}
