import Foundation
enum APIError: LocalizedError {
    case notConfigured
    case unauthorized
    case server(String)
    case invalidResponse
    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Kova API is not connected. Set AppConfig.apiBaseURL to your deployed API URL."
        case .unauthorized: return "Your session expired. Sign in again."
        case .server(let message): return message
        case .invalidResponse: return "The server returned an unexpected response."
        }
    }
}
