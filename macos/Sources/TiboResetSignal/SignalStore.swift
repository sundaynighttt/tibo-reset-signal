import Combine
import Foundation
import UserNotifications

@MainActor
final class SignalStore: ObservableObject {
    @Published private(set) var payload: SignalPayload?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isRefreshing = false
    @Published private(set) var now = Date()

    private let client: SignalClient
    private let cache: SignalCache
    private var clockTimer: Timer?
    private var refreshTimer: Timer?

    init(client: SignalClient = SignalClient(), cache: SignalCache = SignalCache()) {
        self.client = client
        self.cache = cache
        payload = cache.load()
        Task { @MainActor [weak self] in self?.start() }
    }

    func start() {
        guard clockTimer == nil else { return }
        requestNotificationPermission()
        refresh()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.now = Date() }
        }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        let previousLevel = payload?.effectiveLevel(now: now)

        Task {
            do {
                let latest = try await client.fetch()
                payload = latest
                cache.save(latest)
                errorMessage = nil
                let newLevel = latest.effectiveLevel()
                if previousLevel != .green, newLevel == .green {
                    notifyGreenSignal(latest)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isRefreshing = false
            now = Date()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func notifyGreenSignal(_ payload: SignalPayload) {
        let content = UNMutableNotificationContent()
        content.title = "Tibo Reset Signal"
        content.body = "강한 리셋 신호가 감지되었습니다 · \(payload.signal.score)점"
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "green-signal", content: content, trigger: nil)
        )
    }
}
