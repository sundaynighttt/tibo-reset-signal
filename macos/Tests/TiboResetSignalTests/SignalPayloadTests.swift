import Foundation
import XCTest
@testable import TiboResetSignal

final class SignalPayloadTests: XCTestCase {
    func testDecodesAndMarksFreshPayloadGreen() throws {
        let now = Date()
        let json = """
        {
          "schemaVersion": 1,
          "target": {"username": "thsottiaux", "userId": "1"},
          "signal": {"level": "green", "score": 9, "summary": "Strong reset signal"},
          "source": {
            "status": "ok",
            "checkedAt": "\(ISO8601DateFormatter().string(from: now))",
            "lastSuccessfulCheckAt": "\(ISO8601DateFormatter().string(from: now))"
          },
          "apiCredits": {
            "status": "sufficient",
            "checkedAt": "\(ISO8601DateFormatter().string(from: now))",
            "estimatedBalanceUsd": 9.975,
            "estimateRevision": "initial"
          },
          "lastSeenPostId": "10",
          "evidence": []
        }
        """
        let payload = try SignalCoding.decoder().decode(SignalPayload.self, from: Data(json.utf8))
        XCTAssertEqual(payload.effectiveLevel(now: now), .green)
        XCTAssertEqual(SignalFormatter.menuTitle(payload: payload, now: now), "🟢 Reset 9")
        XCTAssertEqual(payload.apiCredits?.status.localizedName, "충분")
        XCTAssertEqual(payload.apiCredits?.localizedDescription, "충분 · 약 $9.97")
    }

    func testOldPayloadIsStale() throws {
        let checked = Date(timeIntervalSince1970: 1_700_000_000)
        let payload = SignalPayload(
            schemaVersion: 1,
            target: SignalTarget(username: "thsottiaux", userId: "1"),
            signal: SignalSummary(level: .red, score: 0, summary: "none"),
            source: SignalSource(
                status: "ok",
                checkedAt: checked,
                lastSuccessfulCheckAt: checked,
                message: nil
            ),
            apiCredits: nil,
            lastSeenPostId: nil,
            evidence: []
        )
        XCTAssertEqual(payload.effectiveLevel(now: checked.addingTimeInterval(7_201)), .stale)
    }
}
