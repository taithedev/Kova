import SwiftUI

struct ExploreView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var query = ""
    @State private var result = SearchResponse(users: [], videos: [])
    @State private var searching = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("DISCOVER / KOVA")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundStyle(KovaTheme.muted)
                            Text("Explore")
                                .font(.system(size: 34, weight: .bold))
                                .tracking(-1)
                        }
                        Spacer()
                        Image(systemName: "safari")
                            .font(.system(size: 25, weight: .light))
                            .foregroundStyle(KovaTheme.foreground)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17))
                            .foregroundStyle(KovaTheme.muted)
                        TextField("Search people, videos, ideas", text: $query)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.search)
                        if !query.isEmpty {
                            Button { query = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(KovaTheme.muted)
                            }
                        }
                    }
                    .padding(17)
                    .kovaGlass(radius: 19)
                    if query.count < 2 {
                        SectionHeading(title: "Find your people", subtitle: "Search creators by name or discover new videos")
                        GlassPanel {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(KovaTheme.banner("glacier"))
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 25))
                                        .foregroundStyle(.white)
                                }
                                .frame(width: 67, height: 67)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Discover creators").font(.system(size: 16, weight: .bold))
                                    Text("Your next favorite community starts here.")
                                        .font(.system(size: 12))
                                        .foregroundStyle(KovaTheme.muted)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        SectionHeading(title: "What moves you?", subtitle: "Look for videos about topics you enjoy")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(["Music", "Gaming", "Creativity", "Life", "Sports", "Art"], id: \.self) { topic in
                                Button {
                                    query = topic.lowercased()
                                } label: {
                                    HStack {
                                        Text(topic).font(.system(size: 14, weight: .bold))
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .foregroundStyle(KovaTheme.muted)
                                    }
                                    .padding(16)
                                    .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 15))
                                }
                                .foregroundStyle(KovaTheme.foreground)
                            }
                        }
                    } else {
                        if searching {
                            ProgressView("Searching Kova…")
                                .tint(KovaTheme.foreground)
                                .frame(maxWidth: .infinity)
                        }
                        if !result.users.isEmpty {
                            SectionHeading(title: "People", subtitle: "\(result.users.count) accounts")
                            ForEach(result.users) { user in
                                NavigationLink { UserProfileView(handle: user.handle) } label: {
                                    HStack(spacing: 12) {
                                        KovaAvatar(name: user.displayName, size: 51, url: user.avatarUrl)
                                        VStack(alignment: .leading, spacing: 5) {
                                            HStack(spacing: 5) {
                                                Text(user.displayName)
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .lineLimit(1)
                                                if user.isVerified { KovaVerifiedBadge(size: 17) }
                                            }
                                            Text("@" + user.handle)
                                                .font(.caption).foregroundStyle(KovaTheme.muted)
                                        }
                                        Spacer()
                                        KovaRoleBadge(role: user.role)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(KovaTheme.muted)
                                    }
                                    .padding(13)
                                    .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 18))
                                }
                                .foregroundStyle(KovaTheme.foreground)
                            }
                        }
                        if !result.videos.isEmpty {
                            SectionHeading(title: "Videos", subtitle: "Approved public posts")
                            ForEach(result.videos) { video in
                                HStack(spacing: 13) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white)
                                        .frame(width: 53, height: 65)
                                        .background(KovaTheme.banner("ink"), in: RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(video.caption.isEmpty ? "Kova video" : video.caption)
                                            .lineLimit(2).font(.system(size: 14, weight: .medium))
                                        Text("@" + video.handle)
                                            .font(.caption).foregroundStyle(KovaTheme.muted)
                                    }
                                    Spacer()
                                }
                                .padding(11)
                                .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        if !searching && result.users.isEmpty && result.videos.isEmpty {
                            EmptyState(icon: "magnifyingglass", title: "No matches",
                                       detail: errorMessage ?? "Try another username or video topic.")
                                .frame(height: 220)
                        }
                    }
                }
                .padding(19)
                .padding(.bottom, 25)
            }
            .background(KovaTheme.background)
            .task(id: query) {
                guard query.count >= 2 else {
                    result = SearchResponse(users: [], videos: [])
                    return
                }
                try? await Task.sleep(for: .milliseconds(350))
                if !Task.isCancelled { await search() }
            }
        }
    }
    private func search() async {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        searching = true
        defer { searching = false }
        do {
            let page: SearchResponse = try await session.api.request("/api/search?q=\(encoded)")
            if !Task.isCancelled { result = page }
        } catch { errorMessage = error.localizedDescription }
    }
}
