import Foundation
struct KovaVideo: Codable, Identifiable, Hashable {
    let id: String
    let caption: String
    let videoUrl: String
    let thumbnailUrl: String?
    let createdAt: String
    let durationSeconds: Double?
    let musicTitle: String?
    let authorId: String?
    let handle: String
    let displayName: String
    let avatarUrl: String?
    let isVerified: Bool?
    var likesCount: Int
    var commentsCount: Int
    var liked: Bool
    var bookmarked: Bool
    var repostsCount: Int
    var reposted: Bool
    var isDemo: Bool = false
    enum CodingKeys: String, CodingKey {
        case id, caption, videoUrl, thumbnailUrl, createdAt, durationSeconds, musicTitle, authorId,
             handle, displayName, avatarUrl, isVerified, likesCount, commentsCount, liked, bookmarked, repostsCount, reposted
    }
    static func == (lhs:KovaVideo,rhs:KovaVideo)->Bool {lhs.id==rhs.id && lhs.liked==rhs.liked && lhs.bookmarked==rhs.bookmarked && lhs.reposted==rhs.reposted}
    func hash(into hasher:inout Hasher){hasher.combine(id)}
}
struct VideoPage: Decodable { let items: [KovaVideo]; let nextCursor: String? }
