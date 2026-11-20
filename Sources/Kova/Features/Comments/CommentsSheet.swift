import SwiftUI

struct CommentsSheet: View {
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    let video: KovaVideo
    @State private var comments: [KovaComment] = []
    @State private var message = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if comments.isEmpty {
                    EmptyState(icon: "bubble.left.and.bubble.right", title: "Start a conversation",
                               detail: "Keep comments kind and respectful.")
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 19) {
                            ForEach(comments) { comment in
                                HStack(alignment: .top, spacing: 11) {
                                    KovaAvatar(name: comment.handle, size: 36)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("@" + comment.handle)
                                            .font(.caption).foregroundStyle(KovaTheme.muted)
                                        Text(comment.body).font(.subheadline)
                                    }
                                    Spacer()
                                    if comment.handle == session.user?.handle {
                                        Button(role: .destructive) {
                                            Task { await deleteComment(comment.id) }
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundStyle(KovaTheme.muted)
                                        }
                                        .accessibilityLabel("Delete your comment")
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
                HStack(spacing: 10) {
                    TextField("Write a kind comment...", text: $message)
                        .padding(14)
                        .background(KovaTheme.panel, in: Capsule())
                    Button { Task { await post() } } label: {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 32))
                    }
                    .disabled(message.trimmingCharacters(in: .whitespaces).isEmpty || session.user == nil)
                }
                .padding(14)
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .background(KovaTheme.background)
            .task { await reload() }
            .alert("Kova", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) { Button("OK") { errorMessage = nil } }
            message: { Text(errorMessage ?? "") }
        }
        .presentationDetents([.medium, .large])
    }
    private func reload() async {
        do {
            let page: CommentPage = try await session.api.request("/api/videos/\(video.id)/comments")
            comments = page.items
        } catch { errorMessage = error.localizedDescription }
    }
    private func post() async {
        do {
            let payload = try session.api.encode(CommentPayload(body: message))
            let _: PostedComment = try await session.api.request("/api/videos/\(video.id)/comments", method: "POST", json: payload)
            message = ""
            await reload()
        } catch { errorMessage = error.localizedDescription }
    }
    private func deleteComment(_ id: String) async {
        do {
            let _: DeletedComment = try await session.api.request("/api/videos/\(video.id)/comments/\(id)", method: "DELETE")
            comments.removeAll { $0.id == id }
        } catch { errorMessage = error.localizedDescription }
    }
}
private struct CommentPayload: Encodable { let body: String }
private struct PostedComment: Decodable { let id: String }
private struct DeletedComment: Decodable { let deleted: Bool }
