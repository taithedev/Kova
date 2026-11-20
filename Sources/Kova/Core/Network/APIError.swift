import Foundation

enum APIError: LocalizedError {
    case notConfigured
    case unauthorized
    case server(String)
    case invalidResponse
    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Kova couldn't connect to its account service."
        case .unauthorized: return "Your session has expired. Sign in again."
        case .server(let message): return message
        case .invalidResponse: return "Kova received an unexpected response. Try again."
        }
    }
}
