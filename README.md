# Tibo Reset Signal

Tibo Reset Signal은 [@thsottiaux](https://x.com/thsottiaux)의 공개 포스트에서 Codex 사용량 리셋 정황을 찾아 신호등으로 보여주는 무료 오픈소스 앱입니다.

> **리셋 버튼은 티보의 손에. 새로고침 노동은 GitHub Actions에게. 우리는 신호등만 보면 됩니다.**

[한국어](#왜-만들었나) · [English summary](#english-summary)

## 왜 만들었나

Codex를 집중적으로 쓰는 Pro 사용자에게 사용량 리셋은 단순한 알림이 아니라 작업 계획과 직결되는 정보입니다. 무거운 작업을 지금 시작할지, 다음 리셋까지 아껴 쓸지 판단하려면 리셋 가능성을 계속 확인하게 됩니다.

그런데 공식적인 리셋 신호는 예고 없이 나타나는 경우가 많고, 커뮤니티가 가장 먼저 주목하는 단서는 티보의 공개 포스트입니다. 농담처럼 말하면 **“리셋 버튼은 결국 티보의 손에 있다”**는 상황입니다. 이 앱은 X를 반복해서 새로고침하지 않아도 그 신호와 근거를 바로 확인하고, 남은 사용량을 더 전략적으로 배분하기 위해 만들었습니다.

## 주요 기능

- **상시 신호등:** macOS 메뉴바, Windows 작업표시줄·미니 위젯·시스템 트레이, iPhone 홈 화면 위젯에서 `🔴 Red / 🟡 Yellow / 🟢 Green` 상태와 점수를 확인합니다.
- **근거 중심 판정:** 신호를 올린 포스트와 판정 이유를 함께 보여주며, 클릭하면 해당 X 원문으로 이동합니다.
- **자동 확인:** 수집기가 1시간마다 새 포스트를 확인하고 앱은 공개 상태를 10분마다 갱신합니다.
- **설정 없는 사용:** 최종 사용자는 API 키, X 로그인, 계정 쿠키, 셀프호스팅을 준비할 필요가 없습니다.
- **투명한 점수 규칙:** reset 표현, 사용량·한도 문맥, 구체적인 시간과 실행 확정 표현을 공개 규칙으로 계산합니다.
- **오래된 정보 구분:** 수집이 2시간 이상 정상적으로 이뤄지지 않으면 Red로 오인하지 않도록 별도의 `Stale` 상태를 표시합니다.
- **운영 비용 확인:** 상세 화면에 X API 크레딧을 `충분 · 약 $9.99`처럼 표시하고, 실제 잔액은 X Developer Console 링크에서 확인할 수 있습니다.
- **개인정보 보호:** 광고, 분석, 텔레메트리가 없으며 최종 사용자의 계정 정보를 수집하지 않고 X 포스트 원문도 공개 JSON에 저장하지 않습니다.

> 이 프로젝트는 X, OpenAI 또는 Tibo의 공식 제품이 아닙니다. 신호는 공개 포스트를 기반으로 한 규칙 기반 추정이며 실제 리셋을 보장하지 않습니다.

## 신호 의미

| 상태 | 의미 |
| --- | --- |
| 🔴 Red | 현재 활성 리셋 신호가 없음 |
| 🟡 Yellow | 사용량·한도 문제 또는 간접적인 리셋 정황이 있음 |
| 🟢 Green | 명확한 리셋 표현과 시간·실행 정황이 함께 감지됨 |
| ⚪ Stale | 수집기가 2시간 이상 정상 확인하지 못함 |

색상만으로 상태를 구분하지 않으며 모든 앱 표면에 상태명이나 점수를 함께 표시합니다.

## 작은 신호등, 꽤 진지한 설계

화면에는 신호등 하나가 보이지만, 그 뒤에서는 몇 가지 현실적인 제품 문제를 함께 풀었습니다.

- **불안정한 외부 데이터:** 공식 X API를 우선 사용하고, 실패하면 검증된 공개 피드로 순차 전환합니다.
- **그럴듯한 말과 실제 신호의 구분:** 단순 키워드 검색 대신 시간, 실행 확정 표현, 사용량 문맥과 부정 표현을 조합한 규칙 엔진으로 점수를 계산합니다.
- **세 플랫폼, 하나의 판단:** GitHub Pages의 작은 JSON 하나를 계약으로 삼아 macOS, Windows, iPhone이 같은 신호와 근거를 보여줍니다.
- **운영 실패를 거짓 정상으로 보이지 않기:** 마지막 정상 값을 보존하되, 수집이 오래 멈추면 별도의 `Stale` 상태로 전환합니다.
- **공짜 앱의 유료 API 비용:** 사용자에게 키를 요구하지 않으면서도 운영자가 비용 소진을 놓치지 않도록 추정 장부와 실제 잔액 확인 경로를 함께 제공합니다.

즉, “포스트를 읽어 색깔을 바꾸는 앱”이라기보다 **외부 신호 수집 → 설명 가능한 판정 → 안전한 공개 배포 → 여러 네이티브 표면**을 작게 끝까지 연결한 프로젝트입니다.

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

## API 잔액 문제를 어떻게 풀었나

처음에는 X API의 실제 잔액을 앱에 그대로 보여주려 했습니다. 하지만 운영자 인증으로 사용할 수 있는 공개 잔액 엔드포인트가 이 계정에서 정상적인 잔액을 반환하지 않았고, Developer Console 내부 요청은 로그인 쿠키에 묶여 있었습니다. 이 요청을 억지로 재사용하면 공개 앱에 계정 쿠키나 추가 인증 절차가 필요해집니다. 잔액 한 줄을 얻자고 보안 모델 전체를 망칠 수는 없었습니다.

그래서 **정확한 척하지 않는 로컬 비용 장부**로 방향을 바꿨습니다.

1. 운영자가 Developer Console에서 확인한 실제 금액을 GitHub 저장소 변수에 시작 잔액으로 등록합니다.
2. 수집기는 `since_id` 이후의 새 Post만 요청하고, 성공 응답에서 실제 반환된 리소스 수만 기록합니다.
3. 시작 잔액에서 새 Post당 `$0.005`, 캐시되지 않은 사용자 조회당 `$0.01`을 차감합니다. 새 Post가 없으면 Post 비용도 차감하지 않습니다.
4. 공개 JSON에는 API 키나 결제정보 대신 추정 잔액, `충분 / 낮음 / 소진` 상태와 계산 기준 버전만 담습니다.
5. 모든 앱 하단에는 [**X Developer Console**](https://console.x.com/) 링크를 두어 실제 잔액이 필요할 때 바로 교차 확인할 수 있게 했습니다.

기본 기준은 추정 잔액 `$1` 미만이면 `낮음`, `$0`이면 `소진`입니다. 단가가 바뀌거나 같은 API 키를 다른 곳에서도 사용하면 실제 잔액과 차이가 날 수 있으므로 화면에도 반드시 `약 $9.99`처럼 표시합니다. 크레딧을 추가 구매하면 시작 잔액과 계산 기준 버전을 함께 갱신해 장부를 다시 맞춥니다.

공개 JSON에는 추정 잔액과 추정 기준 버전만 포함되며 API 키, 결제정보, Developer Console 응답은 포함되지 않습니다. X의 단가 변경, 다른 곳에서 같은 앱 키 사용, 크레딧 추가 구매가 있으면 추정치와 실제 잔액이 달라질 수 있습니다.

공개 피드는 편의를 위한 최선 노력 폴백이며 서비스 지속성을 보장하지 않습니다. 모든 공급자가 실패하면 마지막 정상 신호를 보존하고 수집 상태를 오류로 표시합니다. 앱은 오래된 상태를 Red가 아닌 Stale로 보여줍니다.

공개 상태: `https://sundaynighttt.github.io/tibo-reset-signal/latest.json`

## 설치

GitHub Releases가 제공되면 다음 파일을 내려받을 수 있습니다.

| 운영체제 | 파일 | 지원 환경 |
| --- | --- | --- |
| macOS | `TiboResetSignal-macOS-<버전>.dmg` | macOS 13 이상 |
| Windows | `TiboResetSignal-Windows-<버전>.zip` | Windows 10/11 |

iPhone 앱은 Xcode로 직접 빌드할 수 있습니다. 현재 iPhone 전용 내부 베타는 TestFlight 빌드 `0.1.0 (6)`까지 배포했습니다. 홈 화면 위젯은 큰 단색 원으로 신호를 구분하고 `Tibo Reset`, 가능성 점수, 최신 판정 근거와 X 원문 링크를 함께 보여줍니다.

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

## English summary

Tibo Reset Signal is a free, open-source native utility for macOS, Windows, and iPhone. It displays a rule-based estimate of public Codex reset signals from @thsottiaux as a traffic light. End users need no API key, account, cookie, or self-hosted service. It is unofficial and does not guarantee that a reset will occur.

The native shells are based on patterns proven in the author's [CodexTime](https://github.com/sundaynighttt/codextime) project.

## 라이선스 / License

[MIT](LICENSE)
