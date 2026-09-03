import SwiftUI
import WidgetKit

@main
struct TiboResetSignalWidget: Widget {
    let kind = "TiboResetSignalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SignalTimelineProvider()) { entry in
            TiboResetSignalWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tibo Reset Signal")
        .description("Codex 리셋 가능성을 신호등으로 표시합니다.")
        .supportedFamilies([.systemSmall])
    }
}

struct SignalEntry: TimelineEntry {
    let date: Date
    let payload: SignalPayload?
}

struct SignalTimelineProvider: TimelineProvider {
    private let store = SharedSignalStore()

    func placeholder(in context: Context) -> SignalEntry {
        SignalEntry(date: Date(), payload: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SignalEntry) -> Void) {
        completion(SignalEntry(
            date: Date(),
            payload: context.isPreview ? .placeholder : store.load()
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SignalEntry>) -> Void) {
        Task {
            let payload: SignalPayload?
            do {
                let latest = try await SignalClient().fetch()
                store.save(latest)
                payload = latest
            } catch {
                payload = store.load()
            }
            let now = Date()
            completion(Timeline(
                entries: [SignalEntry(date: now, payload: payload)],
                policy: .after(now.addingTimeInterval(60 * 60))
            ))
        }
    }
}

struct TiboResetSignalWidgetView: View {
    let entry: SignalEntry

    var body: some View {
        let level = entry.payload?.effectiveLevel(now: entry.date) ?? .stale
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Reset")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(intent: RefreshSignalIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .background(.quaternary, in: Circle())
                }
                .buttonStyle(.plain)
                .tint(.secondary)
                .accessibilityLabel("리셋 신호 새로고침")
            }

            Spacer(minLength: 4)

            Circle()
                .fill(level.color.gradient)
                .frame(width: 54, height: 54)
                .shadow(color: level.color.opacity(0.3), radius: 10)
                .accessibilityHidden(true)

            Spacer(minLength: 5)

            Text(level.title)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(scoreText)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(entry.payload?.evidence.first?.url ?? URL(string: "https://x.com/thsottiaux"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tibo 리셋 신호, \(level.title), \(scoreText)")
    }

    private var scoreText: String {
        guard let payload = entry.payload, payload.effectiveLevel(now: entry.date) != .stale else {
            return "확인 지연"
        }
        return "\(payload.signal.score) / 10"
    }
}

#Preview(as: .systemSmall) {
    TiboResetSignalWidget()
} timeline: {
    SignalEntry(date: Date(), payload: .placeholder)
}
