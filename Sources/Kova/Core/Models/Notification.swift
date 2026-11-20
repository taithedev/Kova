import Foundation
struct KovaNotification: Codable, Identifiable {
    let id:String
    let kind:String
    let actorId:String?
    let videoId:String?
    let body:String?
    let isRead:Bool
    let createdAt:String
}
struct NotificationPage:Decodable {let items:[KovaNotification]}
