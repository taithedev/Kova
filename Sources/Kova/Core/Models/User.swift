import Foundation
struct KovaUser: Codable, Identifiable {
    let id: String
    let handle: String
    let displayName: String
    let ageBand: String?
    let role: String?
    let isPrivate: Bool
    let allowMessages: Bool?
    let ageRestricted: Bool?
    var bio: String?
    var avatarUrl: String?
    var isVerified: Bool?
    var followersCount: Int?
    var followingCount: Int?
    var isFollowing: Bool?
    var bannerStyle: String?
    var bannerUrl: String?
    var bannerAnimated: Bool?
    var pronouns: String?
    var staffTitle: String {
        switch role {
        case "owner": return "OWNER"
        case "admin": return "ADMIN"
        case "moderator": return "STAFF"
        case "developer": return "DEVELOPER"
        default: return ""
        }
    }
}
struct AuthResponse: Decodable { let user: KovaUser; let token: String }
