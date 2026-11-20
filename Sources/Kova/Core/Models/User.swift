import Foundation
struct KovaUser: Codable, Identifiable {
    let id: String
    let handle: String
    let displayName: String
    let ageBand: String?
    let role: String?
    let isPrivate: Bool
    let allowMessages: Bool?
    var bio: String?
    var avatarUrl: String?
    var isVerified: Bool?
    var followersCount: Int?
    var followingCount: Int?
    var isFollowing: Bool?
}
struct AuthResponse: Decodable { let user: KovaUser; let token: String }
