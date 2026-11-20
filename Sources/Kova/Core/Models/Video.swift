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
    var isDemo: Bool = false
    enum CodingKeys: String, CodingKey {
        case id, caption, videoUrl, thumbnailUrl, createdAt, durationSeconds, musicTitle, authorId,
             handle, displayName, avatarUrl, isVerified, likesCount, commentsCount, liked, bookmarked
    }
    static func == (lhs:KovaVideo,rhs:KovaVideo)->Bool {lhs.id==rhs.id && lhs.liked==rhs.liked && lhs.bookmarked==rhs.bookmarked}
    func hash(into hasher:inout Hasher){hasher.combine(id)}
}
struct VideoPage: Decodable { let items: [KovaVideo]; let nextCursor: String? }
struct DemoVideos {
    static let samples: [KovaVideo] = [
        KovaVideo(id:"demo-1",caption:"A new space to create. This is a visual preview — not a published video.",videoUrl:"",thumbnailUrl:nil,createdAt:"",durationSeconds:0,musicTitle:"Kova original",authorId:"",handle:"kova",displayName:"Kova Studio",avatarUrl:nil,isVerified:true,likesCount:0,commentsCount:0,liked:false,bookmarked:false,isDemo:true),
        KovaVideo(id:"demo-2",caption:"Big ideas start small. Your next favorite community could be here.",videoUrl:"",thumbnailUrl:nil,createdAt:"",durationSeconds:0,musicTitle:"Create something",authorId:"",handle:"discover",displayName:"Discover Kova",avatarUrl:nil,isVerified:false,likesCount:0,commentsCount:0,liked:false,bookmarked:false,isDemo:true),
        KovaVideo(id:"demo-3",caption:"Your videos. Your people. Your space.",videoUrl:"",thumbnailUrl:nil,createdAt:"",durationSeconds:0,musicTitle:"Original audio",authorId:"",handle:"community",displayName:"Kova Community",avatarUrl:nil,isVerified:false,likesCount:0,commentsCount:0,liked:false,bookmarked:false,isDemo:true)
    ]
}
