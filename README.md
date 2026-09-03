# Tibo Reset Signal

Tibo Reset Signal은 [@thsottiaux](https://x.com/thsottiaux)의 공개 포스트에서 Codex 사용량 리셋 정황을 찾아 신호등으로 보여주는 무료 오픈소스 앱입니다.

- **macOS:** 메뉴바에 `🔴/🟡/🟢 Reset 점수` 표시
- **Windows:** 작업표시줄 또는 우상단 미니 위젯과 시스템 트레이 표시
- **iPhone:** 홈 화면 소형 위젯과 근거 확인 앱
- 사용자 API 키, X 로그인, 쿠키, 셀프호스팅 불필요
- 광고, 분석, 텔레메트리 없음

> 이 프로젝트는 X, OpenAI 또는 Tibo의 공식 제품이 아닙니다. 신호는 공개 포스트를 기반으로 한 규칙 기반 추정이며 실제 리셋을 보장하지 않습니다.

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
  → X API로 @thsottiaux 새 포스트 확인
  → 공개 규칙으로 점수 계산
  → GitHub Pages에 latest.json 배포
  → macOS / Windows / iPhone 앱이 같은 JSON 조회
```

앱에는 API 키가 포함되지 않습니다. 프로젝트 운영자의 X API 키는 GitHub Actions Secret에만 저장됩니다. 수집 중 포스트 텍스트는 점수 계산에만 사용하고 공개 JSON에는 저장하지 않습니다. 공개 데이터에는 계산된 상태, 점수, 판정 이유 코드, Post ID와 X 원문 링크만 포함됩니다.

공개 상태: `https://sundaynighttt.github.io/tibo-reset-signal/latest.json`

## 설치

GitHub Releases가 제공되면 다음 파일을 내려받을 수 있습니다.

| 운영체제 | 파일 | 지원 환경 |
| --- | --- | --- |
| macOS | `TiboResetSignal-macOS-<버전>.dmg` | macOS 13 이상 |
| Windows | `TiboResetSignal-Windows-<버전>.zip` | Windows 10/11 |

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

실제 X API 호출에는 프로젝트 운영 환경의 `X_BEARER_TOKEN`이 필요합니다. 최종 사용자는 이 값을 설정하지 않습니다.

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

1. 저장소 Secret `X_BEARER_TOKEN`을 등록합니다.
2. 필요하면 저장소 Variable `TARGET_USER_ID`를 등록해 사용자 조회 호출을 생략합니다.
3. GitHub Pages Source를 **GitHub Actions**로 설정합니다.
4. `Collect and publish signal` 워크플로를 수동 실행해 첫 정상 JSON을 발행합니다.

포크 저장소는 Secret이 없으면 stale 상태만 발행하며 원본 프로젝트의 API 키를 상속하지 않습니다.

## 개인정보와 보안

- 앱은 사용자 계정이나 X 쿠키를 읽지 않습니다.
- 앱은 공개 GitHub Pages JSON 이외의 데이터를 전송하지 않습니다.
- Actions Secret은 앱·빌드 산출물·공개 JSON에 포함되지 않습니다.
- 민감정보는 이슈나 로그에 첨부하지 마세요. 보안 문제는 [SECURITY.md](SECURITY.md)를 참고하세요.

## English

Tibo Reset Signal is a free, open-source native utility for macOS, Windows, and iPhone. It displays a rule-based estimate of public Codex reset signals from @thsottiaux as a traffic light. End users need no API key, account, cookie, or self-hosted service. It is unofficial and does not guarantee that a reset will occur.

The native shells are based on patterns proven in the author's [CodexTime](https://github.com/sundaynighttt/codextime) project.

## License

[MIT](LICENSE)
