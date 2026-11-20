import SwiftUI

private struct KovaContacts: Decodable {
    let email: String
    let phone: String
    let emailVerified: Bool
    let phoneVerified: Bool
}
private struct KovaContactsPayload: Encodable {
    let email: String
    let phone: String
}
struct PrivateContactsView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var email = ""
    @State private var phone = ""
    @State private var busy = false
    @State private var status: String?

    var body: some View {
        Form {
            Section("OPTIONAL CONTACT DETAILS") {
                TextField("Email address (optional)", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Phone number (optional)", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                Text("For phone numbers, include country code, e.g. +15551234567.")
                    .font(.caption).foregroundStyle(KovaTheme.muted)
            }
            Section("PRIVACY") {
                Label("Only you can view these details in Kova.", systemImage: "lock.shield")
                    .font(.subheadline)
                Text("Neither address is verified, and neither currently enables password recovery. You can leave both blank or clear them whenever you want.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
                Text("Contact details are encrypted in the Kova database and not shown on your public profile.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            Section {
                Button(busy ? "Saving…" : "Save contact details") {
                    Task { await save() }
                }
                .disabled(busy)
                if let status {
                    Text(status).font(.footnote).foregroundStyle(KovaTheme.muted)
                }
            }
        }
        .navigationTitle("Contact information")
        .task { await load() }
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
    }
    private func load() async {
        do {
            let result: KovaContacts = try await session.api.request("/api/account/contact")
            email = result.email
            phone = result.phone
        } catch { status = error.localizedDescription }
    }
    private func save() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            let payload = try session.api.encode(KovaContactsPayload(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
            let result: KovaContacts = try await session.api.request("/api/account/contact", method: "PATCH", json: payload)
            email = result.email
            phone = result.phone
            status = "Contact details saved privately."
        } catch { status = error.localizedDescription }
    }
}
