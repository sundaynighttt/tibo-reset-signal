import AppIntents

struct RefreshSignalIntent: AppIntent {
    static let title: LocalizedStringResource = "리셋 신호 새로고침"
    static let description = IntentDescription("Reset Signal 위젯에서 운영자가 발행한 최신 상태를 다시 읽습니다.")
    static let openAppWhenRun = false
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        .result()
    }
}
