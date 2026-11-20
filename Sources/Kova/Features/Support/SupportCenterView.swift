import SwiftUI

struct KovaTicket: Decodable, Identifiable {
    let id: String
    let subject: String
    let category: String
    let status: String
    let createdAt: String
    let updatedAt: String
    var handle: String? = nil
}
struct KovaTicketPage: Decodable { let items: [KovaTicket] }
struct KovaTicketMessage: Decodable, Identifiable {
    let id: String
    let body: String
    let isStaff: Bool
    let createdAt: String
    let displayName: String
}
struct KovaTicketThread: Decodable {
    let ticket: KovaTicket
    let messages: [KovaTicketMessage]
}
private struct KovaTicketCreate: Encodable {
    let subject: String
    let category: String
    let message: String
}
private struct KovaTicketCreateResult: Decodable { let id: String; let status: String }
private struct KovaTicketReply: Encodable { let message: String }
private struct KovaTicketStatus: Encodable { let status: String }
private struct KovaTicketStatusResult: Decodable { let id: String; let status: String }

struct SupportCenterView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var tickets: [KovaTicket] = []
    @State private var composing = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "lifepreserver")
                        .font(.system(size: 32))
                        .foregroundStyle(KovaTheme.accent)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Kova Support").font(.system(size: 22, weight: .bold))
                        Text("Questions, technical issues, and safety concerns.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                }
                .padding(.vertical, 8)
                Button {
                    composing = true
                } label: {
                    Label("Create a support ticket", systemImage: "plus.bubble")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            Section("MY TICKETS") {
                if tickets.isEmpty {
                    Text("No tickets yet. Contact support whenever you need help.")
                        .font(.footnote).foregroundStyle(KovaTheme.muted)
                }
                ForEach(tickets) { ticket in
                    NavigationLink {
                        SupportTicketThreadView(id: ticket.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 7) {
                            Text(ticket.subject)
                                .font(.system(size: 15, weight: .bold))
                                .lineLimit(2)
                            HStack(spacing: 10) {
                                Text(ticket.category.capitalized)
                                Text(ticket.status.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .foregroundStyle(KovaTheme.accent)
                                Spacer()
                                Text(String(ticket.updatedAt.prefix(10)))
                            }
                            .font(.caption2)
                            .foregroundStyle(KovaTheme.muted)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            if let errorMessage {
                Section {
                    Text(errorMessage).font(.footnote).foregroundStyle(KovaTheme.muted)
                }
            }
        }
        .navigationTitle("Support")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .task { await load() }
        .refreshable { await load() }
        .sheet(isPresented: $composing, onDismiss: { Task { await load() } }) {
            KovaNewTicketView()
        }
    }

    private func load() async {
        do {
            let response: KovaTicketPage = try await session.api.request("/api/support/tickets")
            tickets = response.items
        } catch { errorMessage = error.localizedDescription }
    }
}
private struct KovaNewTicketView: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var category = "technical"
    @State private var ticketMessage = ""
    @State private var busy = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("WHAT DO YOU NEED HELP WITH?") {
                    Picker("Category", selection: $category) {
                        Text("Technical problem").tag("technical")
                        Text("Account help").tag("account")
                        Text("Safety concern").tag("safety")
                        Text("Something else").tag("other")
                    }
                    TextField("Short subject", text: $subject)
                        .textInputAutocapitalization(.sentences)
                    TextEditor(text: $ticketMessage)
                        .frame(minHeight: 150)
                        .accessibilityLabel("Describe your support request")
                    Text("\(ticketMessage.count)/2000")
                        .font(.caption).foregroundStyle(KovaTheme.muted)
                }
                Section {
                    Button(busy ? "Submitting…" : "Send ticket") {
                        Task { await submit() }
                    }
                    .disabled(busy || subject.trimmingCharacters(in: .whitespacesAndNewlines).count < 5
                              || ticketMessage.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 || ticketMessage.count > 2000)
                }
                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(KovaTheme.muted) }
                }
                Section {
                    Text("For an immediate emergency, contact local emergency services. Kova support is not a live emergency line.")
                        .font(.footnote).foregroundStyle(KovaTheme.muted)
                }
            }
            .navigationTitle("New ticket")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() } } }
        }
    }
    private func submit() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            let request = try session.api.encode(KovaTicketCreate(subject: subject.trimmingCharacters(in: .whitespacesAndNewlines),
                                                                category: category, message: ticketMessage.trimmingCharacters(in: .whitespacesAndNewlines)))
            let _: KovaTicketCreateResult = try await session.api.request("/api/support/tickets", method: "POST", json: request)
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}

struct SupportTicketThreadView: View {
    @EnvironmentObject private var session: SessionStore
    let id: String
    @State private var thread: KovaTicketThread?
    @State private var reply = ""
    @State private var sending = false
    @State private var errorMessage: String?
    private var staff: Bool { ["owner","admin","moderator"].contains(session.user?.role ?? "") }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if let thread {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(thread.ticket.subject).font(.title3.bold())
                            Text(thread.ticket.status.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption).foregroundStyle(KovaTheme.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)
                        ForEach(thread.messages) { item in
                            VStack(alignment: .leading, spacing: 7) {
                                HStack {
                                    Text(item.isStaff ? "Kova Support" : item.displayName)
                                        .font(.caption.bold())
                                    Spacer()
                                    Text(String(item.createdAt.prefix(10)))
                                        .font(.caption2).foregroundStyle(KovaTheme.muted)
                                }
                                Text(item.body).font(.subheadline)
                            }
                            .padding(15)
                            .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 17))
                        }
                    } else {
                        ProgressView()
                    }
                    if let errorMessage { Text(errorMessage).font(.footnote).foregroundStyle(KovaTheme.muted) }
                }
                .padding(17)
            }
            .background(KovaTheme.background)
            if thread?.ticket.status != "closed" {
                HStack(spacing: 12) {
                    TextField("Reply to support…", text: $reply, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(11)
                        .background(KovaTheme.panel, in: RoundedRectangle(cornerRadius: 14))
                    Button {
                        Task { await submitReply() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 31))
                            .foregroundStyle(KovaTheme.accent)
                    }
                    .disabled(sending || reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || reply.count > 2000)
                }
                .padding(13)
                .background(KovaTheme.background)
            }
        }
        .navigationTitle("Ticket")
        .toolbar {
            if staff {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(["open","in_progress","resolved","closed"], id: \.self) { value in
                            Button(value.replacingOccurrences(of: "_", with: " ").capitalized) {
                                Task { await changeStatus(value) }
                            }
                        }
                    } label: { Image(systemName: "checkmark.shield") }
                }
            }
        }
        .task { await load() }
    }
    private func load() async {
        do {
            thread = try await session.api.request("/api/support/tickets/\(id)")
        } catch { errorMessage = error.localizedDescription }
    }
    private func submitReply() async {
        sending = true
        defer { sending = false }
        do {
            let body = try session.api.encode(KovaTicketReply(message: reply))
            let _: OkResponse = try await session.api.request("/api/support/tickets/\(id)", method: "POST", json: body)
            reply = ""
            await load()
        } catch { errorMessage = error.localizedDescription }
    }
    private func changeStatus(_ next: String) async {
        do {
            let payload = try session.api.encode(KovaTicketStatus(status: next))
            let _: KovaTicketStatusResult = try await session.api.request("/api/staff/tickets/\(id)", method: "PATCH", json: payload)
            await load()
        } catch { errorMessage = error.localizedDescription }
    }
}

struct StaffSupportView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var tickets: [KovaTicket] = []
    @State private var message: String?
    var body: some View {
        List {
            if tickets.isEmpty {
                Text("No support tickets in the queue.")
                    .foregroundStyle(KovaTheme.muted)
            }
            ForEach(tickets) { ticket in
                NavigationLink { SupportTicketThreadView(id: ticket.id) } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(ticket.subject).font(.headline)
                        HStack {
                            Text(ticket.handle.map { "@"+$0 } ?? "")
                            Text(ticket.category.capitalized)
                            Spacer()
                            Text(ticket.status.capitalized)
                        }
                        .font(.caption).foregroundStyle(KovaTheme.muted)
                    }
                }
            }
            if let message { Text(message).font(.footnote).foregroundStyle(KovaTheme.muted) }
        }
        .navigationTitle("Support queue")
        .task { await load() }
        .refreshable { await load() }
    }
    private func load() async {
        do {
            let page: KovaTicketPage = try await session.api.request("/api/staff/tickets")
            tickets = page.items
        } catch { message = error.localizedDescription }
    }
}
