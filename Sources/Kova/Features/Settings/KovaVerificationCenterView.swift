import SwiftUI

private struct KovaVerificationAccount: Decodable, Identifiable {
    let id: String
    let handle: String
    let displayName: String
    let isVerified: Bool
    let role: String
}
private struct KovaVerificationPage: Decodable { let items: [KovaVerificationAccount] }
private struct KovaVerificationUpdate: Encodable { let isVerified: Bool }
private struct KovaVerificationResponse: Decodable { let handle: String; let isVerified: Bool }

struct KovaVerificationCenterView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var search = ""
    @State private var accounts: [KovaVerificationAccount] = []
    @State private var selected: KovaVerificationAccount?
    @State private var verifying = false
    @State private var message: String?
    @State private var busy = false

    private var authorized: Bool {
        session.hasVerifiedSession &&
        ["owner", "admin"].contains(session.user?.role ?? "")
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 37))
                        .foregroundStyle(KovaTheme.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Verification Center")
                            .font(.system(size: 22, weight: .bold))
                        Text("Award or revoke the Kova blue check.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                }
                .padding(.vertical, 8)
            }
            if authorized {
                Section("FIND AN ACCOUNT") {
                    TextField("Search a username or display name", text: $search)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if search.count < 2 {
                        Text("Type at least two characters. Accounts must be reviewed before a badge is granted.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                }
                Section("ACCOUNTS") {
                    if accounts.isEmpty && search.count >= 2 {
                        Text("No matching accounts.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                    ForEach(accounts) { user in
                        HStack(spacing: 11) {
                            KovaAvatar(name: user.displayName, size: 45)
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(spacing: 6) {
                                    Text(user.displayName).font(.headline).lineLimit(1)
                                    if user.isVerified { KovaVerifiedBadge(size: 17) }
                                }
                                Text("@" + user.handle)
                                    .font(.footnote).foregroundStyle(KovaTheme.muted)
                            }
                            Spacer(minLength: 5)
                            if user.role != "owner" && user.id != session.user?.id {
                                Button(user.isVerified ? "Unverify" : "Verify") {
                                    selected = user
                                    verifying = !user.isVerified
                                }
                                .font(.caption.bold())
                                .buttonStyle(.borderedProminent)
                                .tint(KovaTheme.accent)
                                .disabled(busy)
                            } else {
                                Text(user.role.capitalized)
                                    .font(.caption).foregroundStyle(KovaTheme.muted)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                Section {
                    Label("Only authorized staff can make changes. Every decision is recorded and cannot change an Owner account.", systemImage: "lock.shield")
                        .font(.footnote).foregroundStyle(KovaTheme.muted)
                }
            } else {
                Section {
                    Label("This page is only available to Owners and Admins with a verified active login.", systemImage: "lock.fill")
                        .font(.subheadline).foregroundStyle(KovaTheme.muted)
                }
            }
            if let message {
                Section("STATUS") {
                    Text(message).font(.footnote).foregroundStyle(KovaTheme.muted)
                }
            }
        }
        .navigationTitle("Verification")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .task(id: search) {
            guard authorized, search.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
                accounts = []
                return
            }
            try? await Task.sleep(for: .milliseconds(320))
            if !Task.isCancelled { await load() }
        }
        .refreshable { await load() }
        .confirmationDialog(
            verifying ? "Verify this Kova account?" : "Remove the Kova verification badge?",
            isPresented: Binding(
                get: { selected != nil },
                set: { if !$0 { selected = nil } }
            )
        ) {
            Button(verifying ? "Grant blue check" : "Remove blue check",
                   role: verifying ? nil : .destructive) {
                if let person = selected {
                    selected = nil
                    Task { await update(person, verified: verifying) }
                }
            }
            Button("Cancel", role: .cancel) { selected = nil }
        } message: {
            Text("Staff actions are recorded in the audit log. Verify only genuine accounts.")
        }
    }

    private func load() async {
        guard authorized, search.count >= 2 else { return }
        let q = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        do {
            let result: KovaVerificationPage = try await session.api.request(
                "/api/staff/users?q=\(q)")
            if !Task.isCancelled { accounts = result.items }
            message = nil
        } catch { message = error.localizedDescription }
    }

    private func update(_ user: KovaVerificationAccount, verified: Bool) async {
        guard authorized, !busy else { return }
        busy = true
        defer { busy = false }
        do {
            let payload = try session.api.encode(KovaVerificationUpdate(isVerified: verified))
            let _: KovaVerificationResponse = try await session.api.request(
                "/api/staff/users/\(user.handle)/verification",
                method: "PATCH", json: payload
            )
            message = verified ? "@\(user.handle) is verified." : "@\(user.handle) is no longer verified."
            await load()
        } catch { message = error.localizedDescription }
    }
}
