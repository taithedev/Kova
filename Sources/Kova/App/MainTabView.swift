import SwiftUI

/// A single system TabView plus an animated off-canvas navigation drawer.
/// The standard iOS 26 tab bar continues to use Apple's native Liquid Glass.
struct MainTabView: View {
    @EnvironmentObject private var session: SessionStore
    @AppStorage("kova.selectedTab") private var selected = 0
    @StateObject private var drawer = KovaNavigationState()
    @State private var route: KovaDrawerRoute?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
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
                .environmentObject(drawer)

                if selected != 4 && !drawer.isOpen {
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
                            drawer.isOpen = true
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(KovaTheme.foreground)
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Open Kova navigation")
                    .padding(.leading, 10)
                    .padding(.top, 8)
                    .zIndex(2)
                }

                if drawer.isOpen {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture { closeDrawer() }
                        .transition(.opacity)
                        .zIndex(3)
                    HStack(spacing: 0) {
                        KovaSidebar(
                            selectTab: { index in
                                selected = index
                                closeDrawer()
                            },
                            openPage: { page in
                                closeDrawer()
                                route = page
                            },
                            dismiss: closeDrawer
                        )
                        .environmentObject(session)
                        .frame(width: min(geometry.size.width * 0.85, 337))
                        .transition(.move(edge: .leading))
                        Spacer(minLength: 0)
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .zIndex(4)
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.88), value: drawer.isOpen)
        }
        .sheet(item: $route) { destination in
            KovaSidebarDestination(route: destination)
                .environmentObject(session)
        }
    }

    private func closeDrawer() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.88)) {
            drawer.isOpen = false
        }
    }
}
