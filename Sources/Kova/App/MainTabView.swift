import SwiftUI
struct MainTabView: View {
    @State private var selected: Int = 0
    var body: some View {
        TabView(selection: $selected) {
            FeedView().tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            ExploreView().tabItem { Label("Discover", systemImage: "safari") }.tag(1)
            UploadView().tabItem { Label("Create", systemImage: "plus.app.fill") }.tag(2)
            InboxView().tabItem { Label("Inbox", systemImage: "tray") }.tag(3)
            MyProfileView().tabItem { Label("Profile", systemImage: "person.crop.circle") }.tag(4)
        }
        .tint(.white)
        .toolbarBackground(KovaTheme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
