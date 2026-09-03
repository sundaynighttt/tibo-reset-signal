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
        .contentMarginsDisabled()
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
        Color.clear
            .overlay(alignment: .topLeading) {
                SignalOrb(level: level)
                    .offset(x: -112, y: -108)
            }
            .overlay {
                VStack(alignment: .trailing, spacing: 7) {
                    HStack(spacing: 6) {
                        Spacer()

                        Button(intent: RefreshSignalIntent()) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10, weight: .bold))
                                .frame(width: 24, height: 24)
                                .background(.thinMaterial, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .tint(.secondary)
                        .accessibilityLabel("리셋 신호 새로고침")

                        Text("Tibo Reset")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Text(statusText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    LatestEvidenceView(evidence: entry.payload?.latestEvidence)
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .clipped()
            .accessibilityElement(children: .contain)
    }

    private var statusText: String {
        guard let payload = entry.payload else {
            return SignalLevel.stale.title
        }
        let level = payload.effectiveLevel(now: entry.date)
        guard level != .stale else { return level.title }
        return "\(level.title) (\(payload.signal.score)/10)"
    }
}

private struct SignalOrb: View {
    let level: SignalLevel

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        level.color.opacity(0.98),
                        level.color.opacity(0.72),
                        level.color.opacity(0.18)
                    ],
                    center: .center,
                    startRadius: 4,
                    endRadius: 110
                )
            )
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
                    .padding(10)
            }
            .frame(width: 220, height: 220)
            .shadow(color: level.color.opacity(0.38), radius: 24, x: 8, y: 12)
            .accessibilityHidden(true)
    }
}

private struct LatestEvidenceView: View {
    let evidence: SignalEvidence?

    var body: some View {
        if let evidence {
            Link(destination: evidence.url) {
                evidenceLabel(reasonText: reasonText(for: evidence), showsLink: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("최신 근거, \(reasonText(for: evidence)), 원문 열기")
        } else {
            evidenceLabel(reasonText: "최근 근거 없음", showsLink: false)
                .accessibilityLabel("최근 근거 없음")
        }
    }

    private func evidenceLabel(reasonText: String, showsLink: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text("최신 근거")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                if showsLink {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }

            Text(reasonText)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func reasonText(for evidence: SignalEvidence) -> String {
        let reasons = evidence.reasonCodes
            .prefix(2)
            .map { SignalFormatter.reason($0) }
        return reasons.isEmpty ? "관련 포스트 감지" : reasons.joined(separator: " · ")
    }
}

#Preview(as: .systemSmall) {
    TiboResetSignalWidget()
} timeline: {
    SignalEntry(date: Date(), payload: .placeholder)
}
