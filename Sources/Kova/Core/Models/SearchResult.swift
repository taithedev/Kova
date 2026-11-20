import Foundation
struct UserSearchHit: Decodable, Identifiable {
    let id: String
    let handle: String
    let displayName: String
    let avatarUrl: String?
    let isVerified: Bool
    let role: String?
}
struct VideoSearchHit: Decodable, Identifiable {
    let id: String
    let caption: String
    let videoUrl: String
    let handle: String
    let displayName: String
}
struct SearchResponse: Decodable {
    let users: [UserSearchHit]
    let videos: [VideoSearchHit]
}
struct ProfileResponse: Decodable {
    let profile: KovaUser
    let videos: [ProfileVideo]
}
struct ProfileVideo: Decodable, Identifiable {
    let id: String
    let caption: String
    let videoUrl: String
    let thumbnailUrl: String?
    let createdAt: String
}
