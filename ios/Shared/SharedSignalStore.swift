import Foundation

struct SharedSignalStore: Sendable {
    private static let payloadKey = "signalPayload"

    func load() -> SignalPayload? {
        guard
            let data = defaults.data(forKey: Self.payloadKey),
            let payload = try? SignalCoding.decoder().decode(SignalPayload.self, from: data)
        else {
            return nil
        }
        return payload
    }

    func save(_ payload: SignalPayload) {
        guard let data = try? SignalCoding.encoder().encode(payload) else { return }
        defaults.set(data, forKey: Self.payloadKey)
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: SignalConfiguration.appGroupID) ?? .standard
    }
}
