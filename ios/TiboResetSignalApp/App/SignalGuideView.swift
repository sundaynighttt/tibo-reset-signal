import SwiftUI

struct SignalGuideView: View {
    var body: some View {
        List {
            Section("신호 읽는 방법") {
                guideRow("신호 없음 · 0–2점", "현재 활성 상태인 리셋 관련 근거가 없습니다.")
                guideRow("가능성 있음 · 3–6점", "사용량·한도 문맥이나 간접적인 리셋 정황이 있습니다.")
                guideRow("강한 신호 · 7–10점", "명확한 리셋 표현과 시간·실행 정황 등이 감지되었습니다.")
                guideRow("확인 지연", "데이터 확인에 실패했거나 마지막 정상 확인으로부터 2시간이 지났습니다. 신호 없음과는 다릅니다.")
                Text("점수는 공개된 규칙으로 계산한 신호 강도이며 통계적 확률이 아닙니다. 실제 계정의 사용량·다음 리셋 시각을 조회하거나 변경하지 않습니다.")
            }

            Section("위젯과 갱신") {
                Text("홈 화면을 길게 누른 뒤 편집 → 위젯 추가에서 Reset Signal을 선택하세요. 작은 위젯에서 신호와 최신 근거를 확인하고 새로고침할 수 있습니다.")
                Text("운영 수집기는 약 1시간마다 확인합니다. 새로고침은 이미 공개된 최신 상태를 다시 읽으며, X를 즉시 다시 조회하지 않습니다. 위젯 자동 갱신 시각은 iOS가 결정합니다.")
            }

            Section("출처와 운영") {
                Text("Reset Signal은 운영자가 GitHub Pages에 발행한 Codex 리셋 참고 신호를 읽는 앱입니다. 신호, 점수, 판정 이유와 확인 시각을 앱과 위젯에서 보여줍니다.")
                Text("운영 수집기는 공개된 @thsottiaux 게시물의 리셋 관련 정황을 규칙으로 분석합니다. 앱은 X API를 직접 호출하지 않으며 원문·사진을 복제하지 않고 판정 이유와 외부 원문 링크를 표시합니다.")
                Text("OpenAI, X 또는 Tibo와 제휴하거나 이들이 보증하는 공식 앱이 아닙니다. 서비스와 인물의 명칭은 출처를 설명하기 위해 사용합니다.")
                Text("운영 API 크레딧은 개발자가 부담하는 공용 수집 비용의 추정 잔액입니다. 사용자의 잔액이 아니며 이용자에게 결제나 API 키를 요구하지 않습니다. 콘솔의 실제 잔액은 운영자만 자신의 계정으로 확인할 수 있습니다.")
            }

            Section("개인정보 처리방침") {
                Text("시행일: 2026년 9월 4일 · 운영자: sundaynighttt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("앱은 회원가입, 광고, 추적 또는 분석 SDK를 사용하지 않습니다. 이름, 이메일, 연락처, 위치, 광고 식별자, X 로그인 정보, API 키나 결제정보를 요청하지 않습니다.")
                Text("앱과 위젯은 HTTPS로 GitHub Pages의 공개 상태 파일을 읽습니다. 이 과정에서 IP 주소와 기본 HTTP 요청 정보가 호스팅 제공자인 GitHub에 전달되며 서비스 제공·보안·장애 대응을 위한 접속 기록이 처리될 수 있습니다. 개발자는 개인별 서버 접속 로그를 내려받거나 사용자 프로필을 만들지 않습니다.")
                Text("최근 상태와 판정 근거는 기기의 앱 그룹 저장소에 캐시해 앱과 위젯이 함께 사용합니다. 사용자 계정 데이터가 아닌 공개 신호 데이터입니다. 앱을 삭제하면 앱의 로컬 데이터가 삭제됩니다.")
                Text("원문, 지원 또는 콘솔 링크를 누르면 외부 앱이나 브라우저가 열립니다. 외부 사이트에는 각 서비스의 개인정보 처리방침이 적용됩니다. 지원 문의에 개인정보나 토큰을 공개적으로 올리지 마세요.")
                Text("GitHub가 처리하는 접속 기록의 보관·삭제 요청은 GitHub의 정책과 절차에 따릅니다. 앱 운영자가 해당 기록의 개별 삭제나 보관 기간을 통제하지는 않습니다.")
                Link("GitHub 개인정보 처리방침", destination: URL(string: "https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement")!)
            }

            Section("지원") {
                Link("문의 · 문제 신고", destination: URL(string: "https://github.com/sundaynighttt/tibo-reset-signal/issues")!)
                Link("공개 소스와 점수 규칙", destination: URL(string: "https://github.com/sundaynighttt/tibo-reset-signal")!)
                Text("개인정보 문의는 공개 이슈에 민감정보 없이 연락 방법 안내를 요청하세요. 보안 취약점은 저장소의 Security 안내를 이용하세요.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("신호 안내")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func guideRow(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(detail).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack { SignalGuideView() }
}
