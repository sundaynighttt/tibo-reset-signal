import XCTest
@testable import TiboResetSignal

final class TiboResetSignalTests: XCTestCase {
    func testFreshPayloadUsesSignalLevel() {
        let now = Date()
        let payload = SignalPayload(
            schemaVersion: 1,
            target: SignalTarget(username: "thsottiaux", userId: "1"),
            signal: SignalSummary(level: .green, score: 9, summary: "Strong reset signal"),
            source: SignalSource(
                status: "ok",
                checkedAt: now,
                lastSuccessfulCheckAt: now,
                message: nil
            ),
            apiCredits: APICredits(
                status: .sufficient,
                checkedAt: now,
                estimatedBalanceUsd: 9.975,
                estimateRevision: "initial"
            ),
            lastSeenPostId: "1",
            evidence: []
        )
        XCTAssertEqual(payload.effectiveLevel(now: now), .green)
        XCTAssertEqual(payload.apiCredits?.status.title, "충분")
        XCTAssertEqual(payload.apiCredits?.displayText, "충분 · 약 $9.98")
    }

    func testFailedSourceIsStale() {
        let now = Date()
        let payload = SignalPayload(
            schemaVersion: 1,
            target: SignalTarget(username: "thsottiaux", userId: "1"),
            signal: SignalSummary(level: .red, score: 0, summary: "none"),
            source: SignalSource(
                status: "error",
                checkedAt: now,
                lastSuccessfulCheckAt: now,
                message: "temporary"
            ),
            apiCredits: nil,
            lastSeenPostId: nil,
            evidence: []
        )
        XCTAssertEqual(payload.effectiveLevel(now: now), .stale)
    }
}
