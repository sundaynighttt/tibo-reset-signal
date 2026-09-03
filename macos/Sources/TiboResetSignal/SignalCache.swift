import Foundation

struct SignalCache {
    private var fileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("TiboResetSignal", isDirectory: true)
            .appendingPathComponent("latest.json")
    }

    func load() -> SignalPayload? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? SignalCoding.decoder().decode(SignalPayload.self, from: data)
    }

    func save(_ payload: SignalPayload) {
        guard let fileURL, let data = try? SignalCoding.encoder().encode(payload) else { return }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // A cache failure should not stop live display updates.
        }
    }
}
