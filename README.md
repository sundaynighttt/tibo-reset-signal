# Tibo Reset Signal

Tibo Reset Signal은 [@thsottiaux](https://x.com/thsottiaux)의 공개 포스트에서 Codex 사용량 리셋 정황을 찾아 신호등으로 보여주는 무료 오픈소스 앱입니다.

- **macOS:** 메뉴바에 `🔴/🟡/🟢 Reset 점수` 표시
- **Windows:** 작업표시줄 또는 우상단 미니 위젯과 시스템 트레이 표시
- **iPhone:** 홈 화면 소형 위젯과 근거 확인 앱
- **운영 상태:** 앱 상세 화면에서 X API 크레딧을 `충분 · 약 $9.99`처럼 표시
- 사용자 API 키, X 로그인, 쿠키, 셀프호스팅 불필요
- 광고, 분석, 텔레메트리 없음

> 이 프로젝트는 X, OpenAI 또는 Tibo의 공식 제품이 아닙니다. 신호는 공개 포스트를 기반으로 한 규칙 기반 추정이며 실제 리셋을 보장하지 않습니다.

<!-- project-release-ledger:start -->
## 릴리스 기준과 전체 버전 흐름

> 자동 관리 원장: [`docs/releases/release-ledger.json`](docs/releases/release-ledger.json) · 갱신일: `2026-09-04`

### 현재 기준선

| 기준 | 버전 | 단계 | 상태 | 요약 | 근거 |
| --- | --- | --- | --- | --- | --- |
| 최신 후보<br>`latest_candidate` | **`0.1.0`** | `released` | `active` | macOS DMG와 Windows ZIP을 공개하고 체크섬 및 패키지 구성을 검증한 첫 데스크톱 릴리스 | `git:v0.1.0`<br>[외부 근거](https://github.com/sundaynighttt/tibo-reset-signal/actions/runs/33785528326)<br>[외부 근거](https://github.com/sundaynighttt/tibo-reset-signal/releases/tag/v0.1.0) |
| 외부 공개 최신<br>`last_external` | **`0.1.0`** | `released` | `active` | macOS DMG와 Windows ZIP을 공개하고 체크섬 및 패키지 구성을 검증한 첫 데스크톱 릴리스 | `git:v0.1.0`<br>[외부 근거](https://github.com/sundaynighttt/tibo-reset-signal/actions/runs/33785528326)<br>[외부 근거](https://github.com/sundaynighttt/tibo-reset-signal/releases/tag/v0.1.0) |

### 전체 버전 흐름

| 순서 | 날짜 | 버전 | 단계 | 상태 | 요약 | 근거 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | 2026-09-04 | `0.1.0` | `released` | `active` | macOS DMG와 Windows ZIP을 공개하고 체크섬 및 패키지 구성을 검증한 첫 데스크톱 릴리스 | `git:v0.1.0`<br>[외부 근거](https://github.com/sundaynighttt/tibo-reset-signal/actions/runs/33785528326)<br>[외부 근거](https://github.com/sundaynighttt/tibo-reset-signal/releases/tag/v0.1.0) |
<!-- project-release-ledger:end -->

## 신호 의미

| 상태 | 의미 |
| --- | --- |
| 🔴 Red | 현재 활성 리셋 신호가 없음 |
| 🟡 Yellow | 사용량·한도 문제 또는 간접적인 리셋 정황이 있음 |
| 🟢 Green | 명확한 리셋 표현과 시간·실행 정황이 함께 감지됨 |
| ⚪ Stale | 수집기가 2시간 이상 정상 확인하지 못함 |

색상만으로 상태를 구분하지 않으며 모든 앱 표면에 상태명이나 점수를 함께 표시합니다.

## 작동 방식

```text
GitHub Actions (매시간 17분)
  → 공식 X API로 @thsottiaux 새 포스트 확인
  → API가 없거나 실패하면 검증된 공개 피드 순차 사용
  → 공개 규칙으로 점수 계산
  → GitHub Pages에 latest.json 배포
  → macOS / Windows / iPhone 앱이 같은 JSON 조회
```

앱에는 API 키가 포함되지 않습니다. 프로젝트 운영자의 X API 키가 있으면 GitHub Actions Secret에만 저장됩니다. 키가 없거나 공식 API가 일시 실패하면 수집기는 `codex-reset.com` 공개 Feed, Dayclaw 공개 Source 순서로 전환합니다. 각 폴백은 대상 계정, 작성자, Post ID, 정식 X 링크와 stale 상태를 검증합니다. 수집 중 포스트 텍스트는 점수 계산에만 사용하고 공개 JSON에는 저장하지 않습니다. 공개 데이터에는 계산된 상태, 점수, 판정 이유 코드, Post ID와 X 원문 링크만 포함됩니다.

X의 공개 잔액 API가 현재 계정에서 동작하지 않으므로 크레딧은 로컬 계량 추정치로 표시합니다. 운영자가 등록한 시작 잔액에서 공식 X API가 실제 반환한 새 Post당 `$0.005`, 캐시되지 않은 사용자 조회당 `$0.01`을 차감합니다. 새 Post가 없으면 Post 비용도 차감하지 않습니다. 기본 기준은 추정 잔액 `$1` 미만이면 `낮음`, `$0`이면 `소진`입니다. 이 값은 공식 청구 잔액이 아니며, 각 앱 상세 화면 하단의 **X Developer Console** 링크에서 실제 금액을 확인해야 합니다.

공개 JSON에는 추정 잔액과 추정 기준 버전만 포함되며 API 키, 결제정보, Developer Console 응답은 포함되지 않습니다. X의 단가 변경, 다른 곳에서 같은 앱 키 사용, 크레딧 추가 구매가 있으면 추정치와 실제 잔액이 달라질 수 있습니다.

공개 피드는 편의를 위한 최선 노력 폴백이며 서비스 지속성을 보장하지 않습니다. 모든 공급자가 실패하면 마지막 정상 신호를 보존하고 수집 상태를 오류로 표시합니다. 앱은 오래된 상태를 Red가 아닌 Stale로 보여줍니다.

공개 상태: `https://sundaynighttt.github.io/tibo-reset-signal/latest.json`

## 설치

최신 버전은 [GitHub Releases](https://github.com/sundaynighttt/tibo-reset-signal/releases/latest)에서 내려받을 수 있습니다.

| 운영체제 | 파일 | 지원 환경 |
| --- | --- | --- |
| macOS | `TiboResetSignal-macOS-<버전>.dmg` | macOS 13 이상, Apple Silicon |
| Windows | `TiboResetSignal-Windows-<버전>.zip` | Windows 10/11 |

첫 공개 릴리스의 macOS 앱은 Developer ID 서명·Apple 공증 전이며 Windows 실행 파일도 아직 코드 서명되지 않았습니다. 설치 전 공개 소스와 릴리스의 `SHA256SUMS.txt`를 확인하세요. 운영체제의 실행 차단을 해제하는 방법은 각 릴리스 설명에 적어두었습니다.

iPhone 앱은 Xcode로 직접 빌드할 수 있으며 TestFlight 배포는 별도 릴리스 단계에서 진행합니다.

## 직접 빌드

macOS:

```bash
swift test --package-path macos
./macos/scripts/build-macos.sh
```

Windows(.NET 8 SDK):

```powershell
.\windows\test-windows.ps1
.\windows\package-windows.ps1 -Version 0.1.0
```

iPhone(Xcode와 XcodeGen):

```bash
cd ios
xcodegen generate
./scripts/test-ios.sh
```

수집기:

```bash
python3 -m unittest discover -s tests
python3 -m collector.collect --fixture tests/fixtures/posts.json --output /tmp/latest.json
```

수집기는 기본 `auto` 모드에서 별도 설정 없이 공개 피드로 동작합니다. 프로젝트 운영 환경에 `X_BEARER_TOKEN`을 등록하면 공식 X API가 최우선 소스가 됩니다. 최종 사용자는 어떤 경우에도 이 값을 설정하지 않습니다.

## 점수 규칙

- 명확한 reset 표현: `+5`
- Codex·usage·rate limits 문맥: `+2`
- reset과 결합된 구체적인 시간: `+4`
- reset과 결합된 실행 확정 표현: `+2`
- 조사·효율 문제 정황: `+1`
- 부정 표현: 신호 제거
- `0~2 Red`, `3~6 Yellow`, `7~10 Green`

관련 신호는 Yellow 12시간, Green 24시간 동안 활성 상태로 유지됩니다. 여러 관련 포스트가 겹치면 최대 2점의 결합 가중치를 적용합니다. 규칙과 테스트는 [`collector/scoring.py`](collector/scoring.py)와 [`tests/test_scoring.py`](tests/test_scoring.py)에 공개되어 있습니다.

## 정확도와 제한

- GitHub Actions 예약 실행은 지연되거나 누락될 수 있습니다.
- iOS WidgetKit의 실제 갱신 시각은 시스템이 결정합니다.
- 글의 농담, 부정, 문맥에 따라 오탐이나 누락이 발생할 수 있습니다.
- 앱은 10분마다 공개 JSON을 확인하지만 원천 X 조회는 기본적으로 1시간마다 수행됩니다.
- 포스트 원문은 앱에서 복제하지 않고 X 링크로 엽니다.

## 저장소 구조

```text
collector/  X 조회와 규칙 기반 판정
site/       GitHub Pages로 배포되는 공개 JSON
macos/      Swift/AppKit 메뉴바 앱
windows/    .NET 8 WPF 작업표시줄·트레이 앱
ios/        SwiftUI 앱과 WidgetKit 위젯
schema/     공개 JSON 계약
```

## 운영자 설정

1. GitHub Pages Source를 **GitHub Actions**로 설정합니다.
2. `Collect and publish signal` 워크플로를 수동 실행해 공개 피드 기반 첫 정상 JSON을 발행합니다.
3. 독립성과 안정성을 높이려면 저장소 Secret `X_BEARER_TOKEN`을 등록합니다. 등록 즉시 공식 X API가 우선 사용됩니다.
4. 필요하면 저장소 Variable `TARGET_USER_ID`를 등록해 사용자 조회 호출을 생략합니다.
5. 추정 잔액을 사용하려면 저장소 Variable `X_CREDIT_ESTIMATE_BASE_USD`에 현재 실제 잔액을, `X_CREDIT_ESTIMATE_REVISION`에 고유한 기준 이름을 설정합니다.
6. 크레딧을 추가 구매한 뒤에는 새 실제 잔액으로 `X_CREDIT_ESTIMATE_BASE_USD`를 바꾸고 `X_CREDIT_ESTIMATE_REVISION`도 새 값으로 변경해야 추정치가 재설정됩니다.
7. `낮음` 기준을 바꾸려면 저장소 Variable `X_CREDIT_LOW_USD`에 양수 USD 금액을 설정합니다. 기본값은 `1.0`입니다.

포크 저장소도 Secret 없이 공개 피드 폴백으로 동작하며 원본 프로젝트의 API 키를 상속하지 않습니다. 운영자는 `--source x-api`, `--source codex-reset`, `--source dayclaw`로 특정 공급자를 진단할 수 있습니다.

## 개인정보와 보안

- 앱은 사용자 계정이나 X 쿠키를 읽지 않습니다.
- 앱은 공개 GitHub Pages JSON 이외의 데이터를 전송하지 않습니다.
- Actions Secret은 앱·빌드 산출물·공개 JSON에 포함되지 않습니다.
- X API의 실제 잔액과 결제정보는 저장하지 않습니다. 공개 데이터에는 로컬 계량으로 계산한 추정 잔액과 `충분 / 낮음 / 소진 / 확인 불가` 상태만 포함됩니다.
- 민감정보는 이슈나 로그에 첨부하지 마세요. 보안 문제는 [SECURITY.md](SECURITY.md)를 참고하세요.

## English

Tibo Reset Signal is a free, open-source native utility for macOS, Windows, and iPhone. It displays a rule-based estimate of public Codex reset signals from @thsottiaux as a traffic light. End users need no API key, account, cookie, or self-hosted service. It is unofficial and does not guarantee that a reset will occur.

The native shells are based on patterns proven in the author's [CodexTime](https://github.com/sundaynighttt/codextime) project.

## License

[MIT](LICENSE)
