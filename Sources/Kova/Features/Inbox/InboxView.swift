import SwiftUI
struct InboxView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var notifications: [KovaNotification] = []
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Inbox").font(.kovaDisplay).tracking(-1).padding(.top, 18)
                    GlassPanel {
                        HStack(alignment: .top, spacing: 13) {
                            Image(systemName: "lock.shield").font(.system(size: 27))
                            VStack(alignment: .leading, spacing: 7) {
                                Text("Privacy by default").font(.system(size: 17, weight: .bold))
                                Text("Direct messaging is disabled. Activity and account notices appear here.")
                                    .font(.system(size: 13)).foregroundStyle(KovaTheme.muted)
                            }
                        }
                    }
                    SectionHeading(title: "Activity")
                    if notifications.isEmpty {
                        EmptyState(icon: "bell", title: "Nothing new", detail: "Your activity updates will appear here.")
                            .frame(height: 260)
                    } else {
                        ForEach(notifications) { item in
                            HStack(spacing: 13) {
                                Image(systemName: "bell").font(.system(size: 17))
                                Text(item.body ?? item.kind).font(.system(size: 14))
                                Spacer()
                            }
                            .padding(16)
                            .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .background(KovaTheme.background)
            .task { await load() }
        }
    }
    private func load() async {
        guard session.user != nil else { return }
        if let result: NotificationPage = try? await session.api.request("/api/notifications") {
            notifications = result.items
        }
    }
}
