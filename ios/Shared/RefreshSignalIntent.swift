import AppIntents

struct RefreshSignalIntent: AppIntent {
    static let title: LocalizedStringResource = "리셋 신호 새로고침"
    static let description = IntentDescription("Tibo 리셋 신호 위젯을 최신 정보로 갱신합니다.")
    static let openAppWhenRun = false
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        .result()
    }
}
