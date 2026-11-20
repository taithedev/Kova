import Foundation
private struct APIEnvelope<T: Decodable>: Decodable { let data: T }
private struct APIProblem: Decodable { let error: String }
struct APIClient {
    var token: String?
    private var encoder: JSONEncoder { let e=JSONEncoder(); e.keyEncodingStrategy = .convertToSnakeCase; return e }
    private var decoder: JSONDecoder { let d=JSONDecoder(); d.keyDecodingStrategy = .convertFromSnakeCase; return d }
    func encode<T: Encodable>(_ value: T) throws -> Data { try encoder.encode(value) }
    func request<T: Decodable>(_ path: String, method: String = "GET", json: Data? = nil) async throws -> T {
        guard AppConfig.isConfigured else { throw APIError.notConfigured }
        guard let url = URL(string: path, relativeTo: AppConfig.apiBaseURL)?.absoluteURL else { throw APIError.invalidResponse }
        var req=URLRequest(url:url)
        req.httpMethod=method; req.timeoutInterval=30
        req.setValue("application/json",forHTTPHeaderField:"Accept")
        if let json { req.httpBody=json; req.setValue("application/json",forHTTPHeaderField:"Content-Type") }
        if let token { req.setValue("Bearer \(token)",forHTTPHeaderField:"Authorization") }
        let (data,response)=try await URLSession.shared.data(for:req)
        guard let res=response as? HTTPURLResponse else { throw APIError.invalidResponse }
        if res.statusCode == 401 { throw APIError.unauthorized }
        guard (200..<300).contains(res.statusCode) else {
            let error=try? decoder.decode(APIProblem.self,from:data)
            throw APIError.server(error?.error ?? "Request failed (\(res.statusCode))")
        }
        guard let value=try? decoder.decode(APIEnvelope<T>.self,from:data) else { throw APIError.invalidResponse }
        return value.data
    }
}
