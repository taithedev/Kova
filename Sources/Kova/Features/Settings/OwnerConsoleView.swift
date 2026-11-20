import SwiftUI

private struct OwnerOverview: Decodable {
    let accounts: Int
    let newAccountsWeek: Int
    let approvedVideos: Int
    let pendingVideos: Int
    let openSupport: Int
    let pendingMedia: Int
    let openReports: Int
    let realFollowRelationships: Int
    let events: [OwnerAuditEvent]
    let privilegeEvents: [OwnerAuditEvent]
}
private struct OwnerAuditEvent: Decodable, Identifiable {
    let id: Int
    let action: String
    let createdAt: String
    let actor: String
    let subjectType: String?
    let oldValue: String?
    let newValue: String?
}
struct OwnerConsoleView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var overview: OwnerOverview?
    @State private var message: String?
    private let columns = [GridItem(.flexible()),GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 19) {
                HStack {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("KOVA / MANAGEMENT")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(KovaTheme.muted)
                            .tracking(2)
                        Text("Owner console")
                            .font(.system(size: 29, weight: .bold))
                        Text("Real service activity and moderation tools")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "crown")
                        .font(.system(size: 29))
                        .foregroundStyle(KovaTheme.accent)
                }
                .padding(18)
                .kovaGlass(radius: 22)

                if let overview {
                    LazyVGrid(columns: columns, spacing: 12) {
                        metric("Accounts", overview.accounts, "person.2")
                        metric("New this week", overview.newAccountsWeek, "calendar")
                        metric("Published videos", overview.approvedVideos, "play.rectangle")
                        metric("Awaiting review", overview.pendingVideos, "clock")
                        metric("Support requests", overview.openSupport, "lifepreserver")
                        metric("Media for review", overview.pendingMedia, "photo")
                        metric("Open reports", overview.openReports, "flag")
                        metric("Real follows", overview.realFollowRelationships, "person.badge.plus")
                    }
                    SectionHeading(title: "Management")
                    NavigationLink { StaffDashboardView() } label: {
                        Label("Manage team roles and verification", systemImage: "checkmark.shield")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(15).kovaGlass(radius: 16)
                    }
                    NavigationLink { StaffSupportView() } label: {
                        Label("Resolve support tickets", systemImage: "bubble.left.and.bubble.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(15).kovaGlass(radius: 16)
                    }
                    NavigationLink { StaffMediaReviewView() } label: {
                        Label("Review profile images and GIFs", systemImage: "photo")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(15).kovaGlass(radius: 16)
                    }
                    .foregroundStyle(KovaTheme.foreground)
                    SectionHeading(title: "Latest staff activity", subtitle: "Changes are auditable")
                    ForEach(overview.events) { event in
                        eventRow(event)
                    }
                    SectionHeading(title: "Role and verification changes")
                    ForEach(overview.privilegeEvents) { event in
                        eventRow(event)
                    }
                } else if let message {
                    Text(message).foregroundStyle(KovaTheme.muted)
                } else {
                    ProgressView("Loading service overview…")
                        .tint(KovaTheme.accent)
                }
            }
            .padding(18)
        }
        .background(KovaTheme.background)
        .navigationTitle("Owner")
        .task { await load() }
        .refreshable { await load() }
    }

    private func metric(_ title: String, _ value: Int, _ symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 18)).foregroundStyle(KovaTheme.accent)
            Text(value.formatted(.number.notation(.compactName)))
                .font(.system(size: 29, weight: .bold)).monospacedDigit()
            Text(title)
                .font(.system(size: 12)).foregroundStyle(KovaTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 18))
    }
    private func eventRow(_ event: OwnerAuditEvent) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(event.action.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.system(size: 14, weight: .semibold))
            HStack {
                Text("@" + event.actor)
                Spacer()
                Text(String(event.createdAt.prefix(10)))
            }
            .font(.caption).foregroundStyle(KovaTheme.muted)
        }
        .padding(13)
        .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 13))
    }
    private func load() async {
        guard session.user?.role == "owner" else { return }
        do {
            overview = try await session.api.request("/api/owner/overview")
        } catch { message = error.localizedDescription }
    }
}
