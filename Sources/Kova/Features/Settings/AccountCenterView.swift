import SwiftUI
import UIKit

private struct KovaAccountStats: Decodable {
    let publishedVideos: Int
    let pendingVideos: Int
    let savedVideos: Int
    let comments: Int
    let unreadNotifications: Int
}
private struct KovaSessionItem: Decodable, Identifiable {
    let id: String
    let createdAt: String
    let expiresAt: String
    let isCurrent: Bool
}
private struct KovaSessionPage: Decodable { let items: [KovaSessionItem] }
private struct KovaBlockedAccount: Decodable, Identifiable {
    let handle: String
    let displayName: String
    var id: String { handle }
}
private struct KovaBlockedPage: Decodable { let items: [KovaBlockedAccount] }
private struct KovaRevokeResult: Decodable { let revoked: Int }
private struct KovaUnblockResult: Decodable { let blocked: Bool }
private struct KovaReadResult: Decodable { let markedRead: Int }
private struct KovaHealthResult: Decodable {
    let service: String
    let status: String
    let version: String
}
struct AccountCenterView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var stats: KovaAccountStats?
    @State private var sessions: [KovaSessionItem] = []
    @State private var blocked: [KovaBlockedAccount] = []
    @State private var serviceOnline = false
    @State private var status: String?
    @State private var loading = false
    @State private var confirmingRevoke = false

    var body: some View {
        List {
            Section("YOUR ACCOUNT") {
                if let user = session.user {
                    HStack(spacing: 13) {
                        KovaAvatar(name: user.displayName, size: 52)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName).font(.headline)
                            Text("@" + user.handle).font(.caption).foregroundStyle(KovaTheme.muted)
                        }
                        Spacer()
                        Button {
                            UIPasteboard.general.string = "@" + user.handle
                            status = "Username copied."
                        } label: { Image(systemName: "doc.on.doc") }
                            .accessibilityLabel("Copy username")
                    }
                    LabeledContent("Age group", value: user.ageBand ?? "Unknown")
                    LabeledContent("Account privacy", value: user.isPrivate ? "Private" : "Public")
                    LabeledContent("Direct messages", value: "Disabled")
                }
            }
            Section("ACCOUNT TOOLS") {
                NavigationLink { EditProfileView() } label: { Label("Edit my profile", systemImage: "person.crop.circle") }
                NavigationLink { FollowRequestsView() } label: { Label("Follow requests", systemImage: "person.badge.plus") }
                NavigationLink { BookmarksView() } label: { Label("Saved videos", systemImage: "bookmark") }
                NavigationLink { NotificationsView() } label: { Label("Notification history", systemImage: "bell") }
            }
            Section("YOUR ACTIVITY") {
                if let stats {
                    stat("Published videos", count: stats.publishedVideos)
                    stat("Videos awaiting review", count: stats.pendingVideos)
                    stat("Saved videos", count: stats.savedVideos)
                    stat("Comments posted", count: stats.comments)
                    stat("Unread notifications", count: stats.unreadNotifications)
                } else {
                    Text("No activity details loaded.")
                        .foregroundStyle(KovaTheme.muted)
                }
                Button {
                    Task { await markNotificationsRead() }
                } label: { Label("Mark notifications as read", systemImage: "checkmark.circle") }
            }
            Section("SIGNED-IN SESSIONS") {
                if sessions.isEmpty {
                    Text("No sessions loaded.").foregroundStyle(KovaTheme.muted)
                }
                ForEach(sessions) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Label(item.isCurrent ? "This device" : "Another session",
                                  systemImage: item.isCurrent ? "iphone.gen3" : "lock.shield")
                            Spacer()
                            if item.isCurrent { Text("CURRENT").font(.caption2).bold() }
                        }
                        Text("Session: " + String(item.id.prefix(8)))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(KovaTheme.muted)
                    }
                }
                Button("Sign out other sessions", role: .destructive) {
                    confirmingRevoke = true
                }
                .disabled(sessions.filter { !$0.isCurrent }.isEmpty)
            }
            Section("BLOCKED ACCOUNTS") {
                if blocked.isEmpty { Text("No blocked accounts.").foregroundStyle(KovaTheme.muted) }
                ForEach(blocked) { account in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(account.displayName).bold()
                            Text("@" + account.handle).font(.caption).foregroundStyle(KovaTheme.muted)
                        }
                        Spacer()
                        Button("Unblock") { Task { await unblock(account) } }
                            .buttonStyle(.bordered)
                    }
                }
            }
            Section("CONNECTION") {
                LabeledContent("Kova service", value: serviceOnline ? "Connected" : "Unavailable")
                Button {
                    Task { await reload() }
                } label: {
                    Label(loading ? "Checking..." : "Refresh account information", systemImage: "arrow.clockwise")
                }.disabled(loading)
            }
            if let status {
                Section("STATUS") {
                    Text(status).font(.footnote).foregroundStyle(KovaTheme.muted)
                }
            }
        }
        .navigationTitle("Account center")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .task { await reload() }
        .refreshable { await reload() }
        .confirmationDialog("Sign out other sessions?", isPresented: $confirmingRevoke) {
            Button("Sign out other sessions", role: .destructive) {
                Task { await revokeOtherSessions() }
            }
        } message: {
            Text("Your current iPhone session will stay signed in.")
        }
    }
    private func stat(_ label: String, count: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(count.formatted())
                .foregroundStyle(KovaTheme.muted)
                .monospacedDigit()
        }
    }
    private func reload() async {
        guard session.user != nil, !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let health: KovaHealthResult = try await session.api.request("/api/health")
            serviceOnline = health.status == "ok"
        } catch {
            serviceOnline = false
            status = error.localizedDescription
        }
        do {
            let result: KovaAccountStats = try await session.api.request("/api/users/me/stats")
            stats = result
            let sessionPage: KovaSessionPage = try await session.api.request("/api/auth/sessions")
            sessions = sessionPage.items
            let blockedPage: KovaBlockedPage = try await session.api.request("/api/users/me/blocks")
            blocked = blockedPage.items
        } catch { status = error.localizedDescription }
    }
    private func markNotificationsRead() async {
        do {
            let result: KovaReadResult = try await session.api.request("/api/notifications/read-all", method: "POST")
            status = "\(result.markedRead) notifications marked as read."
            await reload()
        } catch { status = error.localizedDescription }
    }
    private func revokeOtherSessions() async {
        do {
            let result: KovaRevokeResult = try await session.api.request("/api/auth/sessions/revoke-others", method: "POST")
            status = "\(result.revoked) other sessions signed out."
            await reload()
        } catch { status = error.localizedDescription }
    }
    private func unblock(_ account: KovaBlockedAccount) async {
        do {
            let _: KovaUnblockResult = try await session.api.request("/api/users/me/blocks/\(account.handle)", method: "DELETE")
            status = "@" + account.handle + " was unblocked."
            await reload()
        } catch { status = error.localizedDescription }
    }
}
