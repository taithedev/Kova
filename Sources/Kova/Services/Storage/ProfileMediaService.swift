import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ProfileMediaSign: Decodable {
    let key: String
    let url: String
    let method: String
    let mime: String
    let maxBytes: Int
}
struct ProfileMediaResult: Decodable {
    let id: String
    let status: String
    let message: String
}
struct ProfileMediaItem: Decodable, Identifiable {
    let id: String
    let kind: String
    let mime: String
    let status: String
    let createdAt: String
}
struct ProfileMediaPage: Decodable { let items: [ProfileMediaItem] }

enum ProfileMediaService {
    static func upload(_ data: Data, kind: String, mime: String, api: APIClient) async throws -> ProfileMediaResult {
        guard !data.isEmpty && data.count <= 15_000_000 else {
            throw APIError.server("Choose a photo or GIF smaller than 15 MB.")
        }
        let signedBody = try api.encode(ProfileMediaSignPayload(kind: kind, mime: mime))
        let signed: ProfileMediaSign = try await api.request(
            "/api/profile/media/upload-url", method: "POST", json: signedBody
        )
        guard data.count <= signed.maxBytes, let url = URL(string: signed.url), url.scheme == "https" else {
            throw APIError.server("Image too large or storage URL unavailable.")
        }
        var upload = URLRequest(url: url)
        upload.httpMethod = signed.method
        upload.timeoutInterval = 60
        upload.setValue(signed.mime, forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: upload, from: data)
        guard let result = response as? HTTPURLResponse, (200..<300).contains(result.statusCode) else {
            throw APIError.server("Image upload failed. Try a smaller image.")
        }
        let completeBody = try api.encode(ProfileMediaCompletePayload(kind: kind, key: signed.key))
        return try await api.request("/api/profile/media/complete", method: "POST", json: completeBody)
    }

    static func jpeg(from data: Data) throws -> Data {
        guard let original = UIImage(data: data) else {
            throw APIError.server("Select a valid image.")
        }
        // Re-encode photo instead of uploading its original EXIF/geolocation metadata.
        for quality in [0.86, 0.70, 0.55, 0.38] {
            if let compressed = original.jpegData(compressionQuality: quality),
               compressed.count <= 6_000_000 {
                return compressed
            }
        }
        throw APIError.server("That photo is too large. Choose a smaller one.")
    }
}
private struct ProfileMediaSignPayload: Encodable {
    let kind: String
    let mime: String
}
private struct ProfileMediaCompletePayload: Encodable {
    let kind: String
    let key: String
}
