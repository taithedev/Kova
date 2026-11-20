import SwiftUI

private struct StaffOverview: Decodable {
    let openReports: Int
    let pendingVideos: Int
    let liveVideos: Int
    let accounts: Int
    let verifiedAccounts: Int
    let role: String
}
private struct StaffAccount: Decodable, Identifiable {
    let id: String
    let handle: String
    let displayName: String
    let isVerified: Bool
    let role: String
}
private struct StaffUserPage: Decodable { let items: [StaffAccount] }
private struct StaffVerificationResult: Decodable {
    let handle: String
    let isVerified: Bool
}
private struct StaffRoleResult: Decodable {
    let handle: String
    let role: String
}
private struct StaffVerificationPayload: Encodable { let isVerified: Bool }
private struct StaffRolePayload: Encodable { let role: String }

struct StaffDashboardView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var overview: StaffOverview?
    @State private var query = ""
    @State private var users: [StaffAccount] = []
    @State private var busy = false
    @State private var status: String?

    private var role: String { session.user?.role ?? "member" }
    private var canVerify: Bool { role == "admin" || role == "owner" }

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("TEAM / KOVA")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .tracking(2)
                            .foregroundStyle(KovaTheme.muted)
                        Text("Staff dashboard")
                            .font(.system(size: 26, weight: .bold))
                        Text("Moderate content and keep Kova safe.")
                            .font(.subheadline).foregroundStyle(KovaTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 34, weight: .light))
                }
                .padding(.vertical, 8)
            }
            Section("OVERVIEW") {
                if let overview {
                    metric("Published videos", overview.liveVideos, icon: "play.rectangle.on.rectangle")
                    metric("Open reports", overview.openReports, icon: "flag")
                    metric("Accounts", overview.accounts, icon: "person.2")
                    metric("Verified accounts", overview.verifiedAccounts, icon: "checkmark.seal")
                } else {
                    Text("Loading staff statistics…")
                        .foregroundStyle(KovaTheme.muted)
                }
                NavigationLink { KovaAccountSafetyView() } label: {
                    Label("Age and messaging restrictions", systemImage: "lock.shield")
                }
                NavigationLink { ModerationView() } label: {
                    Label("Moderate published videos and reports", systemImage: "checkmark.shield")
                }
            }
            if canVerify {
                Section("ACCOUNT MANAGEMENT") {
                    TextField("Search username to manage", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if users.isEmpty {
                        Text("Enter at least two characters to find an account.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                    ForEach(users) { user in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                KovaAvatar(name: user.displayName, size: 44)
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text(user.displayName).bold().lineLimit(1)
                                        if user.isVerified { KovaVerifiedBadge(size: 16) }
                                    }
                                    Text("@" + user.handle)
                                        .font(.caption).foregroundStyle(KovaTheme.muted)
                                }
                                Spacer()
                                KovaRoleBadge(role: user.role)
                            }
                            if user.role != "owner" && user.id != session.user?.id {
                                HStack(spacing: 8) {
                                    Button(user.isVerified ? "Remove check" : "Verify user") {
                                        Task { await setVerified(user, !user.isVerified) }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(busy)
                                    if role == "owner" {
                                        Menu {
                                            ForEach(["member", "developer", "moderator", "admin"], id: \.self) { next in
                                                Button(next.capitalized) {
                                                    Task { await changeRole(user, next) }
                                                }
                                            }
                                        } label: {
                                            Label("Set role", systemImage: "person.badge.key")
                                        }
                                        .disabled(busy)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            if let status {
                Section("RESULT") {
                    Text(status).font(.footnote).foregroundStyle(KovaTheme.muted)
                }
            }
            Section {
                Text("Every verification and staff-role change is checked and recorded by the server. Admins cannot grant themselves owner access.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
        }
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .navigationTitle("Staff")
        .task { await load() }
        .task(id: query) {
            guard canVerify && query.count >= 2 else { users = []; return }
            try? await Task.sleep(for: .milliseconds(360))
            if !Task.isCancelled { await search() }
        }
        .refreshable { await load() }
    }

    private func metric(_ name: String, _ value: Int, icon: String) -> some View {
        HStack {
            Label(name, systemImage: icon)
            Spacer()
            Text(value.formatted()).bold().monospacedDigit()
        }
    }
    private func load() async {
        guard ["owner", "admin", "moderator"].contains(role) else { return }
        do {
            let result: StaffOverview = try await session.api.request("/api/staff/dashboard")
            overview = result
        } catch { status = error.localizedDescription }
    }
    private func search() async {
        guard canVerify else { return }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        do {
            let page: StaffUserPage = try await session.api.request("/api/staff/users?q=\(encoded)")
            if !Task.isCancelled { users = page.items }
        } catch { status = error.localizedDescription }
    }
    private func setVerified(_ user: StaffAccount, _ verified: Bool) async {
        guard canVerify && !busy else { return }
        busy = true
        defer { busy = false }
        do {
            let payload = try session.api.encode(StaffVerificationPayload(isVerified: verified))
            let _: StaffVerificationResult = try await session.api.request(
                "/api/staff/users/\(user.handle)/verification", method: "PATCH", json: payload)
            status = verified ? "@" + user.handle + " verified." : "Verification removed."
            await search()
            await load()
        } catch { status = error.localizedDescription }
    }
    private func changeRole(_ user: StaffAccount, _ newRole: String) async {
        guard role == "owner" && !busy else { return }
        busy = true
        defer { busy = false }
        do {
            let payload = try session.api.encode(StaffRolePayload(role: newRole))
            let _: StaffRoleResult = try await session.api.request(
                "/api/staff/users/\(user.handle)/role", method: "PATCH", json: payload)
            status = "Role updated to \(newRole)."
            await search()
        } catch { status = error.localizedDescription }
    }
}
