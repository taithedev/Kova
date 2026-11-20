import SwiftUI
import WebKit

private struct StaffMedia: Decodable, Identifiable {
    let id: String
    let kind: String
    let mime: String
    let previewUrl: String
    let createdAt: String
    let handle: String
    let status: String
}
private struct StaffMediaPage: Decodable { let items: [StaffMedia] }
private struct StaffMediaAction: Encodable { let status: String }
private struct StaffMediaResult: Decodable { let id: String; let status: String }

struct StaffMediaReviewView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var items: [StaffMedia] = []
    @State private var busyIDs: Set<String> = []
    @State private var message: String?
    @State private var selectedItem: StaffMedia?
    @State private var filter: String = "all"

    private var visible: [StaffMedia] {
        items.filter { filter == "all" || $0.kind == filter }
    }

    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 31))
                        .foregroundStyle(KovaTheme.accent)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Live profile media").font(.title3.bold())
                        Text("Photos and GIF banners publish immediately. Staff can take down media that breaks Kova's rules.")
                            .font(.footnote).foregroundStyle(KovaTheme.muted)
                    }
                }
                .padding(.vertical, 8)
            }
            Section {
                Picker("Media", selection: $filter) {
                    Text("All").tag("all")
                    Text("Avatars").tag("avatar")
                    Text("Banners").tag("banner")
                }
                .pickerStyle(.segmented)
            }
            Section("CURRENTLY VISIBLE") {
                if visible.isEmpty {
                    Label("No matching uploaded media", systemImage: "photo")
                        .foregroundStyle(KovaTheme.muted)
                }
                ForEach(visible) { item in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 13) {
                            if let url = URL(string: item.previewUrl) {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        ProgressView()
                                    }
                                }
                                .frame(width: 96, height: 96)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("@" + item.handle).font(.headline)
                                Text(item.kind.capitalized + " · " +
                                     (item.mime == "image/gif" ? "Animated GIF" : "Photo"))
                                    .font(.subheadline).foregroundStyle(KovaTheme.muted)
                                Text(String(item.createdAt.prefix(10)))
                                    .font(.caption).foregroundStyle(KovaTheme.muted)
                                Label("Live", systemImage: "checkmark.circle.fill")
                                    .font(.caption).foregroundStyle(KovaTheme.accent)
                            }
                        }
                        Button(role: .destructive) {
                            selectedItem = item
                        } label: {
                            Label("Remove from profile", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .disabled(busyIDs.contains(item.id))
                    }
                    .padding(.vertical, 7)
                }
            }
            if let message {
                Section {
                    Text(message).font(.footnote).foregroundStyle(KovaTheme.muted)
                }
            }
            Section {
                Text("Removing media immediately unlinks it from the profile. The account is notified, and the action is recorded in the staff audit log.")
                    .font(.footnote).foregroundStyle(KovaTheme.muted)
            }
        }
        .navigationTitle("Profile moderation")
        .scrollContentBackground(.hidden)
        .background(KovaTheme.background)
        .task { await load() }
        .refreshable { await load() }
        .confirmationDialog("Remove this image from the creator's profile?",
                            isPresented: Binding(
                                get: { selectedItem != nil },
                                set: { if !$0 { selectedItem = nil } }
                            )) {
            Button("Remove media", role: .destructive) {
                if let item = selectedItem {
                    selectedItem = nil
                    Task { await remove(item) }
                }
            }
            Button("Cancel", role: .cancel) { selectedItem = nil }
        } message: {
            Text("This is a staff takedown. The creator can contact support if they disagree.")
        }
    }

    private func load() async {
        do {
            let result: StaffMediaPage = try await session.api.request("/api/staff/media")
            items = result.items
            message = nil
        } catch { message = error.localizedDescription }
    }
    private func remove(_ item: StaffMedia) async {
        guard !busyIDs.contains(item.id) else { return }
        busyIDs.insert(item.id)
        defer { busyIDs.remove(item.id) }
        do {
            let body = try session.api.encode(StaffMediaAction(status: "rejected"))
            let _: StaffMediaResult = try await session.api.request(
                "/api/staff/media/\(item.id)", method: "PATCH", json: body)
            items.removeAll { $0.id == item.id }
            message = "Media removed from @" + item.handle + "'s profile."
        } catch { message = error.localizedDescription }
    }
}
