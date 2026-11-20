import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var displayName = ""
    @State private var bio = ""
    @State private var isPrivate = true
    @State private var message: String?
    @State private var saving = false

    private var isTeen: Bool { session.user?.ageBand != "18_plus" }

    var body: some View {
        Form {
            Section("PROFILE") {
                TextField("Display name", text: $displayName)
                    .textContentType(.nickname)
                TextField("Bio", text: $bio, axis: .vertical).lineLimit(2...5)
                Text("\(bio.count)/160").font(.caption2).foregroundStyle(KovaTheme.muted)
            }
            Section("PRIVACY") {
                Toggle("Private account", isOn: $isPrivate)
                    .disabled(isTeen)
                    .tint(.white)
                Text(isTeen ? "Teen profiles stay private for safety." : "Private accounts require approval for new followers.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
            Section {
                Button(saving ? "Saving..." : "Save changes") { Task { await save() } }
                    .disabled(saving || displayName.trimmingCharacters(in: .whitespaces).isEmpty || bio.count > 160)
            }
            if let message { Text(message).font(.footnote).foregroundStyle(KovaTheme.muted) }
        }
        .navigationTitle("Edit profile")
        .onAppear {
            displayName = session.user?.displayName ?? ""
            bio = session.user?.bio ?? ""
            isPrivate = isTeen ? true : (session.user?.isPrivate ?? true)
        }
    }
    private func save() async {
        guard !saving else { return }
        saving = true
        defer { saving = false }
        do {
            let payload = try session.api.encode(EditPayload(displayName: displayName, bio: bio, isPrivate: isTeen ? true : isPrivate))
            let user: KovaUser = try await session.api.request("/api/users/me", method: "PATCH", json: payload)
            session.updateUser(user)
            message = "Profile saved."
        } catch { message = error.localizedDescription }
    }
}
private struct EditPayload: Encodable { let displayName: String; let bio: String; let isPrivate: Bool }
