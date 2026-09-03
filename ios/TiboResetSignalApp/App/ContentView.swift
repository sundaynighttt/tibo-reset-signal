import SwiftUI

struct ContentView: View {
    let model: AppModel
    var loadsOnAppear = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if let payload = model.payload {
                        SignalHeroCard(payload: payload)
                        APICreditCard(credits: payload.apiCredits)
                        evidenceSection(payload.evidence)
                    } else if let error = model.errorMessage {
                        ContentUnavailableView(
                            "신호를 불러오지 못했습니다",
                            systemImage: "wifi.exclamationmark",
                            description: Text(error)
                        )
                    } else {
                        ProgressView("신호 확인 중…")
                            .controlSize(.large)
                            .padding(.top, 80)
                    }

                    if let error = model.errorMessage, model.payload != nil {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://console.x.com/")!) {
                        Label("운영자 실제 잔액 확인 · X Developer Console", systemImage: "arrow.up.right.square")
                            .font(.footnote.weight(.semibold))
                    }
                    .padding(.top, 2)

                    NavigationLink {
                        SignalGuideView()
                    } label: {
                        Label("신호 안내 · 개인정보 · 지원", systemImage: "info.circle")
                            .font(.footnote.weight(.semibold))
                    }

                    Text("비공식 참고용 신호입니다. 점수는 리셋 확률이 아니며 실제 리셋을 보장하지 않습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 520)
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Tibo Reset Signal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await model.refresh() }
                    } label: {
                        if model.isRefreshing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(model.isRefreshing)
                    .accessibilityLabel("리셋 신호 새로고침")
                }
            }
        }
        .task {
            guard loadsOnAppear else { return }
            await model.load()
        }
    }

    @ViewBuilder
    private func evidenceSection(_ evidence: [SignalEvidence]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("유력 근거")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if evidence.isEmpty {
                Text("현재 활성 근거가 없습니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.background, in: RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(evidence) { item in
                    Link(destination: item.url) {
                        EvidenceRow(evidence: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct APICreditCard: View {
    let credits: APICredits?

    var body: some View {
        HStack {
            Label("운영 API 크레딧", systemImage: "creditcard")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(credits?.displayText ?? APICreditStatus.unknown.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(credits?.status == .exhausted ? .red : .secondary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("운영자 API 크레딧: \(credits?.displayText ?? APICreditStatus.unknown.title)")
    }
}

private struct SignalHeroCard: View {
    let payload: SignalPayload

    var body: some View {
        let level = payload.effectiveLevel()
        VStack(spacing: 12) {
            Circle()
                .fill(level.color.gradient)
                .frame(width: 88, height: 88)
                .shadow(color: level.color.opacity(0.3), radius: 18)
                .accessibilityHidden(true)

            Text(level.title)
                .font(.title.bold())

            Text(level == .stale ? "–" : "\(payload.signal.score) / 10")
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)

            Text(SignalFormatter.updateText(payload.source.lastSuccessfulCheckAt))
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(level.title), 점수 \(payload.signal.score)점")
    }
}

private struct EvidenceRow: View {
    let evidence: SignalEvidence

    var body: some View {
        HStack(spacing: 12) {
            Text("\(evidence.score)")
                .font(.headline.monospacedDigit())
                .frame(width: 38, height: 38)
                .background(.thinMaterial, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(evidence.reasonCodes.map(SignalFormatter.reason).joined(separator: " · "))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text("X에서 원문 열기")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("가능성 있음") {
    ContentView(
        model: AppModel(initialPayload: .placeholder),
        loadsOnAppear: false
    )
}

#Preview("API 크레딧 상태") {
    VStack(spacing: 12) {
        APICreditCard(credits: APICredits(status: .sufficient, checkedAt: .now, estimatedBalanceUsd: 9.98, estimateRevision: "preview"))
        APICreditCard(credits: APICredits(status: .low, checkedAt: .now, estimatedBalanceUsd: 0.75, estimateRevision: "preview"))
        APICreditCard(credits: APICredits(status: .exhausted, checkedAt: .now, estimatedBalanceUsd: 0, estimateRevision: "preview"))
        APICreditCard(credits: nil)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
