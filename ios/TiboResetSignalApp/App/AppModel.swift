import Foundation
import Observation
import WidgetKit

@MainActor
@Observable
final class AppModel {
    private(set) var payload: SignalPayload?
    private(set) var errorMessage: String?
    private(set) var isRefreshing = false

    private let client: SignalClient
    private let store: SharedSignalStore

    init(
        client: SignalClient = SignalClient(),
        store: SharedSignalStore = SharedSignalStore(),
        initialPayload: SignalPayload? = nil
    ) {
        self.client = client
        self.store = store
        payload = initialPayload
    }

    func load() async {
        if payload == nil { payload = store.load() }
        await refresh()
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let latest = try await client.fetch()
            payload = latest
            store.save(latest)
            errorMessage = nil
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
