import Foundation

struct SignalClient: Sendable {
    let endpoint: URL
    let session: URLSession

    init(endpoint: URL = SignalConfiguration.endpoint, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
    }

    func fetch() async throws -> SignalPayload {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "minute", value: String(Int(Date().timeIntervalSince1970 / 60)))
        ]
        var request = URLRequest(url: components.url ?? endpoint)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200 ..< 300 ~= http.statusCode else {
            throw SignalClientError.invalidResponse
        }
        let payload = try SignalCoding.decoder().decode(SignalPayload.self, from: data)
        guard payload.schemaVersion == 1 else { throw SignalClientError.unsupportedSchema }
        return payload
    }
}

enum SignalClientError: LocalizedError {
    case invalidResponse
    case unsupportedSchema

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "공개 신호 데이터를 받지 못했습니다."
        case .unsupportedSchema: "지원하지 않는 신호 데이터 버전입니다."
        }
    }
}
