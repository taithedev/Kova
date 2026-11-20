import SwiftUI

@MainActor final class KovaNavigationState: ObservableObject {
    @Published var isOpen = false
}

enum KovaDrawerRoute: String, Identifiable {
    case settings, account, editProfile, bookmarks, followRequests, notifications
    case support, contacts, studio, staff, verify, moderation, profileMedia
    case supportQueue, owner
    var id: String { rawValue }
}

struct KovaSidebar: View {
    let selectTab: (Int) -> Void
    let openPage: (KovaDrawerRoute) -> Void
    let dismiss: () -> Void
    @EnvironmentObject private var session: SessionStore

    private var role: String { session.hasVerifiedSession ? session.user?.role ?? "member" : "member" }
    private var staff: Bool { ["owner", "admin", "moderator"].contains(role) }
    private var verifies: Bool { ["owner", "admin"].contains(role) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    KovaMark(size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("KOVA").font(.system(size: 19, weight: .black)).tracking(2)
                        Text("Your space").font(.caption).foregroundStyle(KovaTheme.muted)
                    }
                    Spacer()
                    Button(action: dismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24)).foregroundStyle(KovaTheme.muted)
                    }
                    .accessibilityLabel("Close navigation")
                }
                .padding(.top, 18)

                if let user = session.user {
                    HStack(spacing: 11) {
                        KovaAvatar(name: user.displayName, size: 49, url: user.avatarUrl)
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 6) {
                                Text(user.displayName).font(.headline).lineLimit(1)
                                if user.isVerified == true { KovaVerifiedBadge(size: 17) }
                            }
                            Text("@" + user.handle)
                                .font(.footnote).foregroundStyle(KovaTheme.muted)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KovaTheme.raised, in: RoundedRectangle(cornerRadius: 16))
                }

                drawerSection("EXPLORE") {
                    tab("For You", "play.rectangle.fill", 0)
                    tab("Discover", "safari", 1)
                    tab("Record & Create", "video.badge.plus", 2)
                    tab("Inbox", "tray", 3)
                    tab("My profile", "person.crop.circle", 4)
                }
                if session.user != nil {
                    drawerSection("YOUR ACCOUNT") {
                        page("Edit profile", "person.crop.circle.badge.checkmark", .editProfile)
                        page("Saved videos", "bookmark", .bookmarks)
                        page("Following requests", "person.2", .followRequests)
                        page("Notifications", "bell", .notifications)
                        page("Account center", "person.text.rectangle", .account)
                        page("Settings & appearance", "gearshape", .settings)
                    }
                    drawerSection("SUPPORT") {
                        page("Support tickets", "lifepreserver", .support)
                        page("Private contacts", "envelope.badge.shield.half.filled", .contacts)
                    }
                    if staff {
                        drawerSection("STAFF TOOLS") {
                            page("Moderation", "shield.lefthalf.filled", .moderation)
                            page("Media takedowns", "photo.on.rectangle", .profileMedia)
                            page("Support queue", "bubble.left.and.bubble.right", .supportQueue)
                            page("Staff dashboard", "person.3", .staff)
                            if verifies {
                                page("Verify accounts", "checkmark.seal.fill", .verify)
                            }
                        }
                    }
                    if role == "developer" || role == "owner" {
                        drawerSection("CREATORS") {
                            page("Creator analytics", "chart.bar.xaxis", .studio)
                        }
                    }
                    if role == "owner" {
                        drawerSection("OWNER") {
                            page("Owner console", "crown", .owner)
                        }
                    }
                }
                Text("Kova · 13+ community")
                    .font(.caption2).foregroundStyle(KovaTheme.muted)
                    .padding(.bottom, 26)
            }
            .padding(.horizontal, 17)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .accessibilityAddTraits(.isModal)
    }

    private func drawerSection<Content: View>(_ label: String,
                                                @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(1.7).foregroundStyle(KovaTheme.muted)
                .padding(.horizontal, 11).padding(.bottom, 6)
            content()
        }
    }
    private func entry(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 24)
                Text(title).font(.system(size: 15, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(KovaTheme.muted)
            }
            .foregroundStyle(KovaTheme.foreground)
            .padding(.horizontal, 13).padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
    private func tab(_ title: String, _ icon: String, _ index: Int) -> some View {
        entry(title, icon: icon) { selectTab(index) }
    }
    private func page(_ title: String, _ icon: String, _ route: KovaDrawerRoute) -> some View {
        entry(title, icon: icon) { openPage(route) }
    }
}

struct KovaSidebarDestination: View {
    let route: KovaDrawerRoute
    var body: some View {
        NavigationStack {
            Group {
                switch route {
                case .settings: SettingsView()
                case .account: AccountCenterView()
                case .editProfile: EditProfileView()
                case .bookmarks: BookmarksView()
                case .followRequests: FollowRequestsView()
                case .notifications: NotificationsView()
                case .support: SupportCenterView()
                case .contacts: PrivateContactsView()
                case .studio: DeveloperStudioView()
                case .staff, .verify: StaffDashboardView()
                case .moderation: ModerationView()
                case .profileMedia: StaffMediaReviewView()
                case .supportQueue: StaffSupportView()
                case .owner: OwnerConsoleView()
                }
            }
        }
    }
}
