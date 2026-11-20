import Foundation
import AVFoundation
struct UploadStart:Decodable{let key:String;let url:String;let method:String;let mime:String;let expiresInSeconds:Int;let maxBytes:Int}
struct PublishedVideo:Decodable{let id:String;let status:String;let createdAt:String;let message:String}
private struct UploadRequest:Encodable{let mime:String}
private struct PostVideoRequest:Encodable{let key:String;let caption:String;let durationSeconds:Double;let visibility:String;let musicTitle:String}
struct UploadService {
    let api:APIClient
    func upload(file:URL,caption:String,visibility:String) async throws -> PublishedVideo {
        let attrs=try FileManager.default.attributesOfItem(atPath:file.path)
        let size=(attrs[.size] as? NSNumber)?.intValue ?? 0
        guard size>0 && size<=100*1024*1024 else {throw APIError.server("Choose a video smaller than 100 MB.")}
        let asset=AVURLAsset(url:file)
        let duration=try await asset.load(.duration).seconds
        guard duration>=1 && duration<=600 else{throw APIError.server("Video must be between 1 and 600 seconds.")}
        let mime=file.pathExtension.lowercased()=="mp4" ? "video/mp4" : "video/quicktime"
        let payload=try api.encode(UploadRequest(mime:mime))
        let start:UploadStart=try await api.request("/api/videos/upload-url",method:"POST",json:payload)
        guard let url=URL(string:start.url),url.scheme=="https" else{throw APIError.invalidResponse}
        var request=URLRequest(url:url)
        request.httpMethod="PUT";request.timeoutInterval=180
        request.setValue(mime,forHTTPHeaderField:"Content-Type")
        let (_,response)=try await URLSession.shared.upload(for:request,fromFile:file)
        guard let res=response as? HTTPURLResponse,(200..<300).contains(res.statusCode) else {throw APIError.server("Could not upload video. Check storage settings.")}
        let video=try api.encode(PostVideoRequest(key:start.key,caption:caption,durationSeconds:duration,visibility:visibility,musicTitle:"Original audio"))
        return try await api.request("/api/videos",method:"POST",json:video)
    }
}
