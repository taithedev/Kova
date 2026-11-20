import SwiftUI

/// Shared within a running Kova app session; revisiting tickets won't flash a
/// loading screen or discard already loaded conversations.
@MainActor final class KovaSupportStore: ObservableObject {
    @Published private(set) var tickets: [KovaTicket] = []
    @Published private(set) var conversations: [String: KovaTicketThread] = [:]
    @Published private(set) var staffQueue: [KovaTicket] = []
    @Published private(set) var isLoading = false
    @Published var message: String?

    private var currentAccount: String?
    private var lastTicketFetch: Date?
    private var lastStaffFetch: Date?
    private var activeFetches: Set<String> = []

    func bind(account: String?) {
        guard currentAccount != account else { return }
        currentAccount = account
        tickets = []
        staffQueue = []
        conversations = [:]
        lastTicketFetch = nil
        lastStaffFetch = nil
        activeFetches = []
        message = nil
    }

    func refreshTickets(api: APIClient, force: Bool = false) async {
        guard currentAccount != nil else { return }
        if !force, let lastTicketFetch, Date().timeIntervalSince(lastTicketFetch) < 30 { return }
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        let account = currentAccount
        do {
            let page: KovaTicketPage = try await api.request("/api/support/tickets")
            guard account == currentAccount else { return }
            tickets = page.items
            lastTicketFetch = .now
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }

    func open(_ id: String, api: APIClient, force: Bool = false) async {
        guard currentAccount != nil, !activeFetches.contains(id) else { return }
        if !force && conversations[id] != nil { return }
        activeFetches.insert(id)
        defer { activeFetches.remove(id) }
        let account = currentAccount
        do {
            let details: KovaTicketThread = try await api.request("/api/support/tickets/\(id)")
            guard account == currentAccount else { return }
            conversations[id] = details
            if let index = tickets.firstIndex(where: { $0.id == id }) {
                tickets[index] = details.ticket
            }
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }

    func refreshStaff(api: APIClient, status: String = "all",
                      category: String = "all", query: String = "", force: Bool = false) async {
        guard currentAccount != nil else { return }
        if !force, let lastStaffFetch, Date().timeIntervalSince(lastStaffFetch) < 25,
           status == "all" && category == "all" && query.isEmpty { return }
        let account = currentAccount
        var parts = URLComponents()
        parts.queryItems = [
            URLQueryItem(name: "status", value: status),
            URLQueryItem(name: "category", value: category),
            URLQueryItem(name: "q", value: query)
        ]
        do {
            let page: KovaTicketPage = try await api.request("/api/staff/tickets" + (parts.percentEncodedQuery.map { "?" + $0 } ?? ""))
            guard account == currentAccount else { return }
            staffQueue = page.items
            lastStaffFetch = .now
            message = nil
        } catch { message = error.localizedDescription }
    }

    func invalidate() {
        lastTicketFetch = nil
        lastStaffFetch = nil
    }
}
