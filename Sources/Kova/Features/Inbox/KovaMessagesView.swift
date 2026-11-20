import SwiftUI

private struct KovaDMInboxPage: Decodable { let items: [KovaDMContact] }
private struct KovaDMContact: Decodable, Identifiable {
    let id: String
    let handle: String
    let displayName: String
    let avatarUrl: String?
    let lastMessage: String
    let lastMessageAt: String
    let sentByMe: Bool
}
private struct KovaDMPage: Decodable {
    let user: KovaDMRecipient
    let messages: [KovaDMMessage]
}
private struct KovaDMRecipient: Decodable {
    let id: String
    let handle: String
    let displayName: String
    let avatarUrl: String?
}
private struct KovaDMMessage: Decodable, Identifiable {
    let id: String
    let senderId: String
    let recipientId: String
    let body: String
    let createdAt: String
}
private struct KovaDMCompose: Encodable { let body: String }
private struct KovaDMReportPayload: Encodable {
    let reason: String
    let detail: String
}
private struct KovaDMReportResult: Decodable { let id: String; let status: String }

struct KovaMessagesView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var inbox: [KovaDMContact] = []
    @State private var errorMessage: String?
    @State private var searching = ""

    private var shown: [KovaDMContact] {
        inbox.filter { searching.isEmpty || $0.handle.localizedCaseInsensitiveContains(searching) ||
            $0.displayName.localizedCaseInsensitiveContains(searching) }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Private messages", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.title2.bold())
                    Text("Messages are available when both accounts opt in, mutually follow each other and are in the same age group.")
                        .font(.footnote).foregroundStyle(KovaTheme.muted)
                    NavigationLink { KovaMessagesSettingsView() } label: {
                        Label("Privacy and message settings", systemImage: "lock.shield")
                    }
                }
                .padding(.vertical, 9)
            }
            Section("CONVERSATIONS") {
                if shown.isEmpty {
                    Text("No eligible conversations yet. Follow someone who follows you back, then both enable messaging.")
                        .font(.footnote).foregroundStyle(KovaTheme.muted)
                        .padding(.vertical, 12)
                }
                ForEach(shown) { contact in
                    NavigationLink {
                        KovaConversationView(handle: contact.handle)
                    } label: {
                        HStack(spacing: 11) {
                            KovaAvatar(name: contact.displayName, size: 49, url: contact.avatarUrl)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(contact.displayName).font(.headline)
                                Text("@" + contact.handle + " · " + contact.lastMessage)
                                    .font(.footnote)
                                    .foregroundStyle(KovaTheme.muted)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            if let errorMessage {
                Section { Text(errorMessage).font(.footnote).foregroundStyle(KovaTheme.muted) }
            }
        }
        .searchable(text: $searching, prompt: "Find a conversation")
        .navigationTitle("Messages")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        guard session.user != nil else { return }
        do {
            let page: KovaDMInboxPage = try await session.api.request("/api/messages")
            inbox = page.items
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
}

struct KovaConversationView: View {
    let handle: String
    @EnvironmentObject private var session: SessionStore
    @State private var page: KovaDMPage?
    @State private var draft = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var reported: KovaDMMessage?
    @State private var reportReason = "bullying"
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if let page {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                KovaAvatar(name: page.user.displayName,
                                           size: 48, url: page.user.avatarUrl)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(page.user.displayName).font(.headline)
                                    Text("@" + page.user.handle)
                                        .font(.footnote).foregroundStyle(KovaTheme.muted)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)

                            ForEach(page.messages) { item in
                                bubble(item).id(item.id)
                            }
                        }
                        .padding(15)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: page.messages.count) { _, _ in
                        if let last = page.messages.last {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                composer
            } else if let errorMessage {
                ContentUnavailableView("Conversation unavailable",
                                       systemImage: "lock.shield",
                                       description: Text(errorMessage))
                    .padding()
            } else {
                ProgressView("Opening conversation…")
            }
        }
        .background(KovaTheme.background)
        .navigationTitle("@" + handle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            draft = KovaLocalState.draft(account: session.user?.id ?? "", key: "dm." + handle)
            await load()
        }
        .onChange(of: draft) { _, new in
            guard let account = session.user?.id else { return }
            KovaLocalState.setDraft(new, account: account, key: "dm." + handle)
        }
        .confirmationDialog("Report this message?", isPresented: Binding(
            get: { reported != nil },
            set: { if !$0 { reported = nil } }
        )) {
            ForEach(["bullying","sexual_content","violence","hate","spam","privacy","other"],
                    id: \.self) { reason in
                Button(reason.replacingOccurrences(of: "_", with: " ").capitalized) {
                    if let reported {
                        Task { await submitReport(reported, reason: reason) }
                    }
                    reported = nil
                }
            }
            Button("Cancel", role: .cancel) { reported = nil }
        } message: {
            Text("Kova staff receives a report ID and reason. Use Block on the user's profile to stop contact.")
        }
    }

    private func bubble(_ item: KovaDMMessage) -> some View {
        let outgoing = item.senderId == session.user?.id
        return HStack {
            if outgoing { Spacer(minLength: 48) }
            Text(item.body)
                .font(.system(size: 15))
                .textSelection(.enabled)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .foregroundStyle(outgoing ? Color.white : KovaTheme.foreground)
                .background(outgoing ? KovaTheme.accent : KovaTheme.panel,
                            in: RoundedRectangle(cornerRadius: 19))
                .contextMenu {
                    Button("Report message", systemImage: "flag") {
                        reported = item
                    }
                }
            if !outgoing { Spacer(minLength: 48) }
        }
    }

    private var composer: some View {
        VStack(spacing: 9) {
            HStack(alignment: .bottom, spacing: 11) {
                TextField("Message…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($focused)
                    .padding(12)
                    .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 16))
                Button { Task { await send() } } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(KovaTheme.accent)
                }
                .disabled(isSending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          draft.count > 1000)
                .accessibilityLabel("Send message")
            }
            Text("Messages are limited to mutual follows in your age group. Avoid sharing personal contact information.")
                .font(.system(size: 10))
                .foregroundStyle(KovaTheme.muted)
                .multilineTextAlignment(.center)
            if let errorMessage {
                Text(errorMessage).font(.caption).foregroundStyle(KovaTheme.muted)
            }
        }
        .padding(.horizontal, 13).padding(.vertical, 9)
    }

    private func load() async {
        do {
            page = try await session.api.request("/api/messages/\(handle)")
            errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }
    private func send() async {
        guard !isSending else { return }
        isSending = true
        defer { isSending = false }
        do {
            let payload = try session.api.encode(KovaDMCompose(body: draft))
            let _: KovaDMMessage = try await session.api.request(
                "/api/messages/\(handle)", method: "POST", json: payload)
            draft = ""
            await load()
        } catch { errorMessage = error.localizedDescription }
    }
    private func submitReport(_ item: KovaDMMessage, reason: String) async {
        do {
            let payload = try session.api.encode(KovaDMReportPayload(
                reason: reason, detail: "Reported in private conversation with @" + handle))
            let _: KovaDMReportResult = try await session.api.request(
                "/api/messages/report/\(item.id)", method: "POST", json: payload)
            errorMessage = "Your report has been submitted to Kova staff."
        } catch { errorMessage = error.localizedDescription }
    }
}

private struct KovaMessageOptions: Decodable {
    let allowMessages: Bool
    let ageRestricted: Bool
    let restrictions: String?
}
private struct KovaMessageOptionPayload: Encodable { let allowMessages: Bool }

struct KovaMessagesSettingsView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var allow = false
    @State private var ageRestricted = false
    @State private var saving = false
    @State private var status: String?

    var body: some View {
        Form {
            Section {
                Toggle("Allow eligible mutual followers to message me", isOn: $allow)
                    .tint(KovaTheme.accent)
                    .disabled(saving || ageRestricted)
                Text("Off by default. Both accounts must enable messaging and follow one another. Messaging stays within the same age group. Adults cannot message teen accounts.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            Section("SAFETY") {
                Label("Block an account from their profile.", systemImage: "hand.raised")
                Label("Report individual messages from the conversation.", systemImage: "flag")
                Label("Direct messages do not permit links or phone numbers.", systemImage: "lock.shield")
                if ageRestricted {
                    Text("Kova staff has restricted messaging on this account. Your profile privacy setting is unchanged.")
                        .font(.footnote).foregroundStyle(KovaTheme.muted)
                }
            }
            Section {
                Button("Save messaging preferences") { Task { await save() } }
                    .disabled(saving || session.user == nil)
            }
            if let status {
                Section { Text(status).font(.footnote).foregroundStyle(KovaTheme.muted) }
            }
        }
        .navigationTitle("Message settings")
        .task { await load() }
    }

    private func load() async {
        guard session.user != nil else { return }
        do {
            let options: KovaMessageOptions = try await session.api.request("/api/account/messages")
            allow = options.allowMessages
            ageRestricted = options.ageRestricted
        } catch { status = error.localizedDescription }
    }
    private func save() async {
        guard !saving else { return }
        saving = true
        defer { saving = false }
        do {
            let data = try session.api.encode(KovaMessageOptionPayload(allowMessages: allow))
            let _: KovaMessageOptions = try await session.api.request(
                "/api/account/messages", method: "PATCH", json: data)
            status = "Message preferences saved."
            if let updated: KovaUser = try? await session.api.request("/api/auth/me") {
                session.updateUser(updated)
            }
        } catch { status = error.localizedDescription }
    }
}
