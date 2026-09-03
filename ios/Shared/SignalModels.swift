import Foundation

enum SignalLevel: String, Codable, Equatable, Sendable {
    case red
    case yellow
    case green
    case stale

    var title: String {
        switch self {
        case .red: "신호 없음"
        case .yellow: "가능성 있음"
        case .green: "강한 신호"
        case .stale: "확인 지연"
        }
    }
}

struct SignalTarget: Codable, Equatable, Sendable {
    let username: String
    let userId: String?
}

struct SignalSummary: Codable, Equatable, Sendable {
    let level: SignalLevel
    let score: Int
    let summary: String
}

struct SignalSource: Codable, Equatable, Sendable {
    let status: String
    let checkedAt: Date?
    let lastSuccessfulCheckAt: Date?
    let message: String?
}

struct SignalEvidence: Codable, Equatable, Identifiable, Sendable {
    let postId: String
    let url: URL
    let score: Int
    let reasonCodes: [String]
    let detectedAt: Date
    let activeUntil: Date

    var id: String { postId }
}

struct SignalPayload: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let target: SignalTarget
    let signal: SignalSummary
    let source: SignalSource
    let lastSeenPostId: String?
    let evidence: [SignalEvidence]

    func effectiveLevel(now: Date = Date()) -> SignalLevel {
        guard
            source.status == "ok",
            let lastSuccess = source.lastSuccessfulCheckAt,
            now.timeIntervalSince(lastSuccess) <= 2 * 60 * 60
        else {
            return .stale
        }
        return signal.level
    }

    static let placeholder = SignalPayload(
        schemaVersion: 1,
        target: SignalTarget(username: "thsottiaux", userId: "1"),
        signal: SignalSummary(level: .yellow, score: 5, summary: "Possible reset signal"),
        source: SignalSource(
            status: "ok",
            checkedAt: Date(),
            lastSuccessfulCheckAt: Date(),
            message: nil
        ),
        lastSeenPostId: "1",
        evidence: [
            SignalEvidence(
                postId: "1",
                url: URL(string: "https://x.com/thsottiaux")!,
                score: 5,
                reasonCodes: ["reset_mention", "usage_context"],
                detectedAt: Date(),
                activeUntil: Date().addingTimeInterval(12 * 60 * 60)
            )
        ]
    )
}

enum SignalCoding {
    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

enum SignalFormatter {
    static func reason(_ code: String) -> String {
        switch code {
        case "explicit_reset": "명확한 리셋 표현"
        case "reset_mention": "리셋 언급"
        case "specific_time": "구체적인 시간"
        case "commitment": "실행 확정 표현"
        case "usage_context": "사용량·한도 문맥"
        case "investigation": "문제 조사 정황"
        case "negated": "부정 표현"
        default: code.replacingOccurrences(of: "_", with: " ")
        }
    }

    static func updateText(_ date: Date?, now: Date = Date()) -> String {
        guard let date else { return "확인 기록 없음" }
        let minutes = max(0, Int(now.timeIntervalSince(date) / 60))
        if minutes < 1 { return "방금 확인" }
        if minutes < 60 { return "\(minutes)분 전 확인" }
        return "\(minutes / 60)시간 전 확인"
    }
}
