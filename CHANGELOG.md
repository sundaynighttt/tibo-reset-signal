# 변경 이력 / Changelog

## iPhone 1.0 (10) — Reset Signal

- 앱·홈 화면 이름과 위젯 제목·갤러리 이름을 `Reset Signal`로 변경했습니다.
- 특정 인물보다 운영자가 GitHub Pages에 발행하는 Codex 리셋 참고 지표를 확인하는 기능에 초점을 맞췄습니다.
- 실제 원천과 외부 원문 링크 안내는 유지하며, 개인 계정 리셋 조회·실행이나 공식 서비스로 오인시키지 않습니다.
- 앱 ID·App Group·위젯 kind·JSON 주소·점수 규칙은 유지했습니다. 기존 설치와 캐시 연결은 그대로입니다.
- 기존 macOS·Windows 릴리스와 과거 버전 이름은 소급 변경하지 않습니다. 배포 상태는 릴리스 원장과 제출 자료를 따릅니다.

## 0.1.0

### 한국어

- 매시간 새 포스트를 확인하는 X API 수집기와 공개 신호 JSON 계약을 추가했습니다.
- X API를 사용할 수 없을 때 검증된 Codex Reset·Dayclaw 공개 피드로 전환하도록 구성했습니다.
- 운영자 X API 크레딧 상태와 로컬 계량 추정 잔액을 표시하고, 실제 잔액을 확인할 수 있는 X Developer Console 링크를 추가했습니다.
- macOS 네이티브 메뉴바 앱을 추가했습니다.
- Windows 작업표시줄·플로팅 미니 위젯·시스템 트레이 앱을 추가했습니다.
- iPhone 전용 SwiftUI 앱과 WidgetKit 홈 화면 위젯을 추가하고 TestFlight 빌드 `0.1.0 (8)`까지 배포했습니다.
- iPhone 위젯 상단에 `Tibo Reset`과 새로고침 버튼을 양끝 정렬하고, 가능성 문구와 점수를 왼쪽 정렬로 배치했습니다.
- 가능성 문구는 검정색 15pt, 점수는 1pt 작은 14pt로 구분하고 최신 판정 근거와 X 원문 링크를 함께 표시했습니다.
- 위젯 신호를 큰 단색 원으로 다듬고 흰색 내부선·그라데이션·그림자를 제거해 상태 색상을 선명하게 구분했습니다.
- macOS·Windows·iPhone 교차 플랫폼 CI와 GitHub Pages 배포 워크플로를 추가했습니다.

### English summary

- Added an hourly X collector with verified public-feed fallbacks and a public signal schema.
- Added native macOS, Windows, and iPhone clients with cross-platform CI and GitHub Pages publishing.
- Added transparent operator API-credit estimation with a direct link to X Developer Console for the actual balance.
- Shipped the iPhone-only TestFlight build `0.1.0 (8)` with a 10% larger solid-color signal, a balanced title/refresh header, a left-aligned score, latest evidence, and the original-post link.
