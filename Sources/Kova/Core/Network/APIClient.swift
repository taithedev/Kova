import Foundation

private struct APIEnvelope<T: Decodable>: Decodable { let data: T }
private struct APIProblem: Decodable { let error: String }

struct APIClient {
    var token: String?

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    func encode<T: Encodable>(_ value: T) throws -> Data { try encoder.encode(value) }

    func request<T: Decodable>(_ path: String, method: String = "GET", json: Data? = nil) async throws -> T {
        guard let url = URL(string: path, relativeTo: AppConfig.apiBaseURL)?.absoluteURL,
              url.scheme == "https" else { throw APIError.invalidResponse }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 25
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let json {
            req.httpBody = json
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw APIError.server("Couldn't reach Kova. Check your internet connection and try again.")
        }
        guard let res = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(res.statusCode) else {
            if let detail = try? decoder.decode(APIProblem.self, from: data) {
                throw APIError.server(detail.error)
            }
            if res.statusCode == 401 { throw APIError.unauthorized }
            if res.statusCode == 429 { throw APIError.server("Too many attempts. Try again in a few minutes.") }
            if res.statusCode == 404 { throw APIError.server("This feature isn't available on the Kova server.") }
            throw APIError.server("Request failed (\(res.statusCode)). Try again.")
        }
        guard let envelope = try? decoder.decode(APIEnvelope<T>.self, from: data) else {
            throw APIError.invalidResponse
        }
        return envelope.data
    }
}
