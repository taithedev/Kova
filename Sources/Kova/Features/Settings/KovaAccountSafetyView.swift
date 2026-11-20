import SwiftUI

private struct KovaSafetyAccount: Decodable, Identifiable {
    let id: String
    let handle: String
    let displayName: String
    let role: String
    let ageRestricted: Bool
}
private struct KovaSafetyAccountPage: Decodable { let items: [KovaSafetyAccount] }
private struct KovaSafetyPayload: Encodable {
    let ageRestricted: Bool
    let reason: String
}
private struct KovaSafetyResult: Decodable { let handle: String; let ageRestricted: Bool }

struct KovaAccountSafetyView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var query = ""
    @State private var accounts: [KovaSafetyAccount] = []
    @State private var selected: KovaSafetyAccount?
    @State private var targetRestricted = false
    @State private var reason = "age_safety"
    @State private var busy = false
    @State private var message: String?

    private var canModerate: Bool {
        session.hasVerifiedSession &&
        ["owner", "admin", "moderator"].contains(session.user?.role ?? "")
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 29))
                        .foregroundStyle(KovaTheme.accent)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Age & account safety").font(.title3.bold())
                        Text("Restrict messaging without making profiles private.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                }
                .padding(.vertical, 9)
            }
            Section("STAFF SAFETY CONTROLS") {
                Text("Kova is a 13+ community and does not host 18+ content. A safety restriction keeps the current public/private account setting unchanged while disabling direct messages. These restrictions are recorded and can be appealed through support.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            if canModerate {
                Section {
                    TextField("Search a username", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker("Reason", selection: $reason) {
                        Text("Age safety").tag("age_safety")
                        Text("Harassment report").tag("harassment")
                        Text("Privacy concern").tag("privacy")
                        Text("Staff review").tag("staff_review")
                    }
                }
                Section("ACCOUNTS") {
                    if accounts.isEmpty && query.count >= 2 {
                        Text("No matching accounts.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                    ForEach(accounts) { person in
                        HStack(spacing: 12) {
                            KovaAvatar(name: person.displayName, size: 44)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(person.displayName).font(.headline)
                                Text("@" + person.handle + " · " + person.role.capitalized)
                                    .font(.footnote).foregroundStyle(KovaTheme.muted)
                                if person.ageRestricted {
                                    Label("Messaging restricted", systemImage: "lock.shield")
                                        .font(.caption2)
                                        .foregroundStyle(KovaTheme.accent)
                                }
                            }
                            Spacer(minLength: 5)
                            if person.role != "owner" && person.id != session.user?.id {
                                Button(person.ageRestricted ? "Restore" : "Restrict") {
                                    selected = person
                                    targetRestricted = !person.ageRestricted
                                }
                                .buttonStyle(.bordered)
                                .disabled(busy)
                            }
                        }
                    }
                }
            } else {
                Section { Text("Staff access is required.") }
            }
            if let message {
                Section { Text(message).font(.footnote).foregroundStyle(KovaTheme.muted) }
            }
        }
        .navigationTitle("Account safety")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .task(id: query) {
            guard canModerate, query.count >= 2 else { accounts = []; return }
            try? await Task.sleep(for: .milliseconds(300))
            if !Task.isCancelled { await load() }
        }
        .refreshable { await load() }
        .confirmationDialog(
            targetRestricted ? "Restrict messaging on this account?" : "Lift the messaging restriction?",
            isPresented: Binding(
                get: { selected != nil },
                set: { if !$0 { selected = nil } }
            )
        ) {
            Button(targetRestricted ? "Apply restriction" : "Restore eligibility",
                   role: targetRestricted ? .destructive : nil) {
                if let user = selected { Task { await change(user) } }
                selected = nil
            }
            Button("Cancel", role: .cancel) { selected = nil }
        } message: {
            Text("The profile will not become private. A staff action is logged and the account will be notified.")
        }
    }

    private func load() async {
        guard canModerate && query.count >= 2 else { return }
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        do {
            let result: KovaSafetyAccountPage = try await session.api.request("/api/staff/users?q=\(q)")
            accounts = result.items
            message = nil
        } catch { message = error.localizedDescription }
    }
    private func change(_ person: KovaSafetyAccount) async {
        guard canModerate, !busy else { return }
        busy = true
        defer { busy = false }
        do {
            let payload = try session.api.encode(KovaSafetyPayload(
                ageRestricted: targetRestricted, reason: reason))
            let _: KovaSafetyResult = try await session.api.request(
                "/api/staff/users/\(person.handle)/safety",
                method: "PATCH", json: payload
            )
            message = targetRestricted ?
                "Messaging restricted for @\(person.handle)." :
                "Restriction lifted for @\(person.handle)."
            await load()
        } catch { message = error.localizedDescription }
    }
}
