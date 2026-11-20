import SwiftUI

private struct StudioOverview: Decodable {
    let role: String
    let publishedVideos: Int
    let pendingVideos: Int
    let followers: Int
    let totalLikes: Int
    let features: [String]
}
struct DeveloperStudioView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var overview: StudioOverview?
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 9) {
                        Text("KOVA / STUDIO")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(KovaTheme.muted)
                        Text("Creator studio")
                            .font(.system(size: 28, weight: .bold))
                        HStack(spacing: 8) {
                            KovaRoleBadge(role: session.user?.role)
                            Text("Creator insights")
                                .font(.caption).foregroundStyle(KovaTheme.muted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let overview {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        metric("Followers", overview.followers, icon: "person.2")
                        metric("Total likes", overview.totalLikes, icon: "heart")
                        metric("Published", overview.publishedVideos, icon: "play.rectangle")
                        metric("Awaiting review", overview.pendingVideos, icon: "clock")
                    }
                    Text("Studio stats come from your real Kova activity.")
                        .font(.footnote).foregroundStyle(KovaTheme.muted)
                } else {
                    ProgressView().tint(KovaTheme.foreground)
                }
                NavigationLink { MyProfileView() } label: {
                    Label("View my creator profile", systemImage: "person.crop.circle")
                        .font(.system(size: 15, weight: .bold))
                        .padding(15)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .kovaGlass(radius: 16)
                }
                .foregroundStyle(KovaTheme.foreground)
                Text("Developer access includes the studio and a developer badge. It never grants access to another person's account or private content.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
                if let message { Text(message).font(.footnote).foregroundStyle(KovaTheme.muted) }
            }
            .padding(18)
        }
        .background(KovaTheme.background)
        .navigationTitle("Studio")
        .task { await load() }
        .refreshable { await load() }
    }
    private func metric(_ label: String, _ value: Int, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(KovaTheme.muted)
            Text(value.formatted(.number.notation(.compactName)))
                .font(.system(size: 30, weight: .bold))
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(KovaTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 18))
    }
    private func load() async {
        do {
            let result: StudioOverview = try await session.api.request("/api/developer/overview")
            overview = result
        } catch { message = error.localizedDescription }
    }
}
