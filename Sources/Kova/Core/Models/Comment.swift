import Foundation
struct KovaComment: Codable, Identifiable {
    let id:String
    let body:String
    let createdAt:String
    let handle:String
    let displayName:String
    let avatarUrl:String?
}
struct CommentPage:Decodable {let items:[KovaComment]}
