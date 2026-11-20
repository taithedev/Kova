import SwiftUI

struct KovaTicket: Decodable, Identifiable {
    let id: String
    let subject: String
    let category: String
    let status: String
    let priority: String
    let createdAt: String
    let updatedAt: String
    let unread: Bool
    let handle: String?
}

struct KovaTicketPage: Decodable {
    let items: [KovaTicket]
    let open: Int?
    let unread: Int?
}

struct KovaTicketMessage: Decodable, Identifiable {
    let id: String
    let body: String
    let isStaff: Bool
    let createdAt: String
    let displayName: String
}

struct KovaTicketEvent: Decodable, Identifiable {
    let id: Int
    let eventType: String
    let createdAt: String
}

struct KovaTicketThread: Decodable {
    let ticket: KovaTicket
    let messages: [KovaTicketMessage]
    let events: [KovaTicketEvent]?
}

private struct NewSupportTicketPayload: Encodable {
    let subject: String
    let category: String
    let message: String
}
private struct NewSupportTicketResponse: Decodable {
    let id: String
    let status: String
}
private struct TicketReplyPayload: Encodable { let message: String }
private struct TicketStatusPayload: Encodable { let status: String }
private struct TicketPriorityPayload: Encodable { let priority: String }
private struct TicketStatusResponse: Decodable { let id: String; let status: String }
private struct TicketPriorityResponse: Decodable { let id: String; let priority: String }

struct SupportCenterView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var support: KovaSupportStore
    @State private var showNewTicket = false
    @State private var search = ""
    @State private var selectedFilter = "all"

    private var shownTickets: [KovaTicket] {
        support.tickets.filter { ticket in
            let matchFilter = selectedFilter == "all" ||
                (selectedFilter == "active" && ["open","in_progress"].contains(ticket.status)) ||
                (selectedFilter == "resolved" && ["resolved","closed"].contains(ticket.status))
            let matchSearch = search.isEmpty || ticket.subject.localizedCaseInsensitiveContains(search) ||
                ticket.category.localizedCaseInsensitiveContains(search)
            return matchFilter && matchSearch
        }
    }
    private var unreadCount: Int { support.tickets.filter(\.unread).count }
    private var activeCount: Int {
        support.tickets.filter { ["open","in_progress"].contains($0.status) }.count
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 17) {
                    HStack(spacing: 13) {
                        Image(systemName: "lifepreserver.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(KovaTheme.accent)
                            .frame(width: 50, height: 50)
                            .kovaGlass(radius: 17)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kova Support")
                                .font(.system(size: 24, weight: .heavy))
                            Text("Real people helping you, all in one place.")
                                .font(.footnote)
                                .foregroundStyle(KovaTheme.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    HStack(spacing: 12) {
                        supportStat("Active", activeCount, "tray.full")
                        supportStat("Unread", unreadCount, "envelope.badge")
                    }
                    Button {
                        showNewTicket = true
                    } label: {
                        Label("New support ticket", systemImage: "square.and.pencil")
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 45)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(KovaTheme.accent)
                }
                .padding(.vertical, 8)
            }
            Section {
                Picker("Show tickets", selection: $selectedFilter) {
                    Text("All").tag("all")
                    Text("Active").tag("active")
                    Text("Resolved").tag("resolved")
                }
                .pickerStyle(.segmented)
            }
            Section("YOUR CONVERSATIONS") {
                if shownTickets.isEmpty {
                    VStack(spacing: 13) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 32))
                            .foregroundStyle(KovaTheme.muted)
                        Text(support.tickets.isEmpty ? "No tickets yet" : "No matching tickets")
                            .font(.headline)
                        Text("Your support history is saved to your account.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 35)
                }
                ForEach(shownTickets) { ticket in
                    NavigationLink {
                        SupportTicketThreadView(id: ticket.id)
                    } label: {
                        HStack(alignment: .top, spacing: 11) {
                            Image(systemName: ticket.category == "safety" ? "shield.lefthalf.filled" : "text.bubble")
                                .foregroundStyle(KovaTheme.accent)
                                .frame(width: 27, height: 27)
                            VStack(alignment: .leading, spacing: 7) {
                                HStack(spacing: 7) {
                                    Text(ticket.subject)
                                        .font(.system(size: 15, weight: ticket.unread ? .bold : .semibold))
                                        .lineLimit(2)
                                    if ticket.unread {
                                        Circle().fill(KovaTheme.accent).frame(width: 8, height: 8)
                                    }
                                    Spacer(minLength: 0)
                                }
                                HStack(spacing: 7) {
                                    KovaSupportStatus(status: ticket.status)
                                    Text(ticket.category.capitalized)
                                        .font(.caption2).foregroundStyle(KovaTheme.muted)
                                }
                                HStack {
                                    Text("Ticket #" + String(ticket.id.prefix(8)).uppercased())
                                    Spacer()
                                    Text(String(ticket.updatedAt.prefix(10)))
                                }
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(KovaTheme.muted)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            Section {
                Text("Replies are saved to your account and can be viewed again after restarting Kova. Support is not an emergency service. Never share your password in a ticket.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            if let message = support.message {
                Section { Text(message).font(.footnote).foregroundStyle(KovaTheme.muted) }
            }
        }
        .searchable(text: $search, prompt: "Search your tickets")
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Support")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .task {
            support.bind(account: session.user?.id)
            await support.refreshTickets(api: session.api)
        }
        .refreshable {
            await support.refreshTickets(api: session.api, force: true)
        }
        .sheet(isPresented: $showNewTicket, onDismiss: {
            Task { await support.refreshTickets(api: session.api, force: true) }
        }) {
            NewSupportTicketSheet()
                .environmentObject(session)
                .environmentObject(support)
        }
    }

    private func supportStat(_ label: String, _ count: Int, _ symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(KovaTheme.accent)
            Text(count.formatted()).font(.system(size: 17, weight: .bold))
            Text(label).font(.caption).foregroundStyle(KovaTheme.muted)
            Spacer()
        }
        .padding(12)
        .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 15))
    }
}

struct KovaSupportStatus: View {
    let status: String
    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 10, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(KovaTheme.raised, in: Capsule())
    }
    private var title: String {
        switch status {
        case "in_progress": return "In progress"
        case "resolved": return "Resolved"
        case "closed": return "Closed"
        default: return "Open"
        }
    }
    private var icon: String {
        switch status {
        case "in_progress": return "clock"
        case "resolved": return "checkmark.circle"
        case "closed": return "lock"
        default: return "circle.dotted"
        }
    }
}

private struct NewSupportTicketSheet: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var support: KovaSupportStore
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var category = "technical"
    @State private var message = ""
    @State private var sending = false
    @State private var errorText: String?
    @FocusState private var messageFocused: Bool

    private var accountID: String { session.user?.id ?? "" }
    private var canSubmit: Bool {
        subject.trimmingCharacters(in: .whitespacesAndNewlines).count >= 5 &&
        subject.count <= 100 &&
        message.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 &&
        message.count <= 2000 && !sending
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 27))
                            .foregroundStyle(KovaTheme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("New ticket").font(.title3.bold())
                            Text("Talk directly to Kova support.")
                                .font(.footnote).foregroundStyle(KovaTheme.muted)
                        }
                    }
                    .padding(.vertical, 7)
                }
                Section("WHAT'S GOING ON?") {
                    Picker("Category", selection: $category) {
                        Label("Technical issue", systemImage: "wrench").tag("technical")
                        Label("My account", systemImage: "person.crop.circle").tag("account")
                        Label("Safety or harassment", systemImage: "shield").tag("safety")
                        Label("Something else", systemImage: "ellipsis").tag("other")
                    }
                    TextField("Brief subject", text: $subject)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.next)
                    ZStack(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Describe what happened. Include any relevant error messages, but never passwords.")
                                .foregroundStyle(KovaTheme.muted)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $message)
                            .frame(minHeight: 140)
                            .focused($messageFocused)
                            .scrollContentBackground(.hidden)
                            .accessibilityLabel("Support request details")
                    }
                    HStack {
                        Image(systemName: "checkmark.shield")
                        Text("Draft saved on this iPhone")
                        Spacer()
                        Text("\(message.count)/2000")
                    }
                    .font(.caption2)
                    .foregroundStyle(KovaTheme.muted)
                }
                Section {
                    Button {
                        Task { await sendTicket() }
                    } label: {
                        HStack {
                            Spacer()
                            if sending { ProgressView().padding(.trailing, 8) }
                            Label("Submit ticket", systemImage: "paperplane.fill")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                        }
                        .padding(7)
                    }
                    .disabled(!canSubmit)
                }
                Section {
                    Text("You can close this screen and return later without losing your draft. Safety concerns are prioritized for staff review.")
                        .font(.footnote).foregroundStyle(KovaTheme.muted)
                    if let errorText {
                        Text(errorText).font(.footnote)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(KovaTheme.background)
            .navigationTitle("Contact support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Clear unsent draft", systemImage: "trash", role: .destructive) {
                            subject = ""
                            message = ""
                            category = "technical"
                        }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .onAppear { restoreDraft() }
            .onChange(of: subject) { _, value in save(value, key: "new.subject") }
            .onChange(of: category) { _, value in save(value, key: "new.category") }
            .onChange(of: message) { _, value in save(value, key: "new.message") }
        }
    }

    private func save(_ value: String, key: String) {
        guard !accountID.isEmpty else { return }
        KovaLocalState.setDraft(value, account: accountID, key: key)
    }
    private func restoreDraft() {
        guard !accountID.isEmpty else { return }
        subject = KovaLocalState.draft(account: accountID, key: "new.subject")
        category = KovaLocalState.draft(account: accountID, key: "new.category")
        if category.isEmpty { category = "technical" }
        message = KovaLocalState.draft(account: accountID, key: "new.message")
    }
    private func sendTicket() async {
        guard canSubmit else { return }
        sending = true
        defer { sending = false }
        do {
            let payload = try session.api.encode(NewSupportTicketPayload(
                subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category,
                message: message.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
            let response: NewSupportTicketResponse = try await session.api.request(
                "/api/support/tickets", method: "POST", json: payload)
            save("", key: "new.subject")
            save("", key: "new.message")
            save("", key: "new.category")
            support.invalidate()
            await support.refreshTickets(api: session.api, force: true)
            // Keep server ticket ID; it is also available from the ticket list.
            if !response.id.isEmpty { dismiss() }
        } catch { errorText = error.localizedDescription }
    }
}

struct SupportTicketThreadView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var support: KovaSupportStore
    let id: String
    @State private var reply = ""
    @State private var sending = false
    @State private var errorMessage: String?
    @FocusState private var replyFocused: Bool

    private var thread: KovaTicketThread? { support.conversations[id] }
    private var accountID: String { session.user?.id ?? "" }
    private var staffRole: Bool { ["owner","admin","moderator"].contains(session.user?.role ?? "") }
    private var canModerate: Bool {
        staffRole && thread?.ticket.handle != session.user?.handle &&
            thread?.ticket.handle != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 13) {
                        if let thread {
                            header(thread.ticket)
                            ForEach(thread.messages) { item in
                                messageBubble(item)
                                    .id(item.id)
                            }
                            if let events = thread.events, !events.isEmpty {
                                DisclosureGroup("Ticket activity") {
                                    ForEach(events) { item in
                                        HStack {
                                            Image(systemName: "clock.arrow.circlepath")
                                            Text(item.eventType.replacingOccurrences(of: "_", with: " ").capitalized)
                                            Spacer()
                                            Text(String(item.createdAt.prefix(10)))
                                        }
                                        .font(.caption).foregroundStyle(KovaTheme.muted)
                                    }
                                }
                                .padding(14)
                                .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 13))
                            }
                        } else {
                            ProgressView("Opening conversation…")
                                .padding(.top, 60)
                                .frame(maxWidth: .infinity)
                        }
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote).foregroundStyle(KovaTheme.muted)
                        }
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: thread?.messages.count) { _, _ in
                    if let last = thread?.messages.last?.id {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }
            .background(KovaTheme.background)

            if thread?.ticket.status != "closed" {
                composer
            }
        }
        .navigationTitle("Ticket #" + String(id.prefix(8)).uppercased())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Refresh conversation", systemImage: "arrow.clockwise") {
                        Task { await refresh() }
                    }
                    if canModerate {
                        Section("STATUS") {
                            ForEach(["open","in_progress","resolved","closed"], id: \.self) { status in
                                Button(status.replacingOccurrences(of: "_", with: " ").capitalized) {
                                    Task { await changeStatus(status) }
                                }
                            }
                        }
                        Section("PRIORITY") {
                            ForEach(["normal","high","urgent"], id: \.self) { priority in
                                Button(priority.capitalized) {
                                    Task { await changePriority(priority) }
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(KovaTheme.accent)
                }
            }
        }
        .task {
            support.bind(account: session.user?.id)
            if !accountID.isEmpty {
                reply = KovaLocalState.draft(account: accountID, key: "reply." + id)
            }
            await support.open(id, api: session.api)
        }
        .onChange(of: reply) { _, value in
            guard !accountID.isEmpty else { return }
            KovaLocalState.setDraft(value, account: accountID, key: "reply." + id)
        }
        .refreshable {
            await refresh()
        }
    }

    private func header(_ ticket: KovaTicket) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(ticket.category.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(KovaTheme.muted)
                    .tracking(1.4)
                Spacer()
                KovaSupportStatus(status: ticket.status)
            }
            Text(ticket.subject)
                .font(.system(size: 22, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Label("Ticket #" + String(ticket.id.prefix(8)).uppercased(), systemImage: "number")
                Spacer()
                if canModerate {
                    Text(ticket.priority.uppercased())
                        .foregroundStyle(KovaTheme.accent)
                }
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(KovaTheme.muted)
            Text("Messages are stored privately on Kova. You can return to this conversation whenever you need.")
                .font(.footnote).foregroundStyle(KovaTheme.muted)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kovaGlass(radius: 20)
        .padding(.bottom, 6)
    }

    private func messageBubble(_ item: KovaTicketMessage) -> some View {
        let isStaff = item.isStaff
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(isStaff ? "Kova Support" : item.displayName,
                      systemImage: isStaff ? "checkmark.shield" : "person.crop.circle")
                    .font(.system(size: 12, weight: .bold))
                Spacer()
                Text(String(item.createdAt.prefix(16)).replacingOccurrences(of: "T", with: " "))
                    .font(.system(size: 10))
                    .foregroundStyle(KovaTheme.muted)
            }
            Text(item.body)
                .font(.system(size: 14))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isStaff ? KovaTheme.raised : KovaTheme.panel,
                    in: RoundedRectangle(cornerRadius: 18))
        .overlay(alignment: .leading) {
            if isStaff {
                RoundedRectangle(cornerRadius: 2)
                    .fill(KovaTheme.accent)
                    .frame(width: 3)
                    .padding(.vertical, 14)
            }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 11) {
            TextField("Write a reply…", text: $reply, axis: .vertical)
                .lineLimit(1...5)
                .focused($replyFocused)
                .padding(12)
                .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 16))
            Button {
                Task { await sendReply() }
            } label: {
                if sending {
                    ProgressView().frame(width: 30, height: 30)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(KovaTheme.accent)
                }
            }
            .accessibilityLabel("Send support reply")
            .disabled(sending || reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || reply.count > 2000)
        }
        .padding(12)
        .background(KovaTheme.background)
    }

    private func refresh() async {
        await support.open(id, api: session.api, force: true)
        await support.refreshTickets(api: session.api, force: true)
    }
    private func sendReply() async {
        guard !sending else { return }
        sending = true
        defer { sending = false }
        do {
            let payload = try session.api.encode(TicketReplyPayload(
                message: reply.trimmingCharacters(in: .whitespacesAndNewlines)))
            let _: OkResponse = try await session.api.request(
                "/api/support/tickets/\(id)", method: "POST", json: payload)
            reply = ""
            await refresh()
        } catch { errorMessage = error.localizedDescription }
    }
    private func changeStatus(_ status: String) async {
        do {
            let payload = try session.api.encode(TicketStatusPayload(status: status))
            let _: TicketStatusResponse = try await session.api.request(
                "/api/staff/tickets/\(id)", method: "PATCH", json: payload)
            await refresh()
        } catch { errorMessage = error.localizedDescription }
    }
    private func changePriority(_ priority: String) async {
        do {
            let payload = try session.api.encode(TicketPriorityPayload(priority: priority))
            let _: TicketPriorityResponse = try await session.api.request(
                "/api/staff/tickets/\(id)/priority", method: "PATCH", json: payload)
            await refresh()
        } catch { errorMessage = error.localizedDescription }
    }
}

struct StaffSupportView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var support: KovaSupportStore
    @State private var search = ""
    @State private var statusFilter = "all"
    @State private var categoryFilter = "all"

    var body: some View {
        List {
            Section("QUEUE FILTERS") {
                Picker("Status", selection: $statusFilter) {
                    Text("All").tag("all")
                    Text("Open").tag("open")
                    Text("In progress").tag("in_progress")
                    Text("Resolved").tag("resolved")
                    Text("Closed").tag("closed")
                }
                Picker("Category", selection: $categoryFilter) {
                    Text("All").tag("all")
                    Text("Technical").tag("technical")
                    Text("Account").tag("account")
                    Text("Safety").tag("safety")
                    Text("Other").tag("other")
                }
                Text("Safety concerns receive higher priority.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            Section("SUPPORT CONVERSATIONS") {
                if support.staffQueue.isEmpty {
                    Text("No matching support requests.")
                        .font(.footnote).foregroundStyle(KovaTheme.muted)
                }
                ForEach(support.staffQueue) { ticket in
                    NavigationLink {
                        SupportTicketThreadView(id: ticket.id)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            if ticket.unread {
                                Circle().fill(KovaTheme.accent)
                                    .frame(width: 9, height: 9)
                                    .padding(.top, 5)
                            }
                            VStack(alignment: .leading, spacing: 7) {
                                Text(ticket.subject)
                                    .font(.system(size: 15, weight: ticket.unread ? .bold : .semibold))
                                HStack(spacing: 9) {
                                    KovaSupportStatus(status: ticket.status)
                                    Text(ticket.priority.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(KovaTheme.accent)
                                }
                                HStack {
                                    Text(ticket.handle.map { "@" + $0 } ?? "")
                                    Spacer()
                                    Text(String(ticket.updatedAt.prefix(10)))
                                }
                                .font(.caption2).foregroundStyle(KovaTheme.muted)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            if let message = support.message {
                Section { Text(message).font(.footnote).foregroundStyle(KovaTheme.muted) }
            }
        }
        .searchable(text: $search, prompt: "Search by username or subject")
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Support queue")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .task {
            support.bind(account: session.user?.id)
            await fetch(force: true)
        }
        .task(id: "\(statusFilter):\(categoryFilter):\(search)") {
            try? await Task.sleep(for: .milliseconds(330))
            if !Task.isCancelled { await fetch(force: true) }
        }
        .refreshable { await fetch(force: true) }
    }

    private func fetch(force: Bool) async {
        await support.refreshStaff(api: session.api, status: statusFilter,
                                   category: categoryFilter, query: search, force: force)
    }
}
