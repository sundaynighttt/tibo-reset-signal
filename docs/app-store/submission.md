# iPhone App Store 제출 자료

## 대상과 현재 상태

- 앱: Reset Signal (이전 이름: Tibo Reset Signal) · Apple ID `6808099012`
- 번들: `com.sundaynighttt.tiboresetsignal.ios`
- 버전: `1.0 (10)` · iPhone 전용 · iOS 17 이상 · App Store 심사 대기 중
- 이전 `1.0 (9)`는 App Store Connect 처리 완료 및 심사 빌드 연결을 확인했다. 새 빌드 10의 검증·업로드 상태는 아래에 별도로 기록한다.
- 2026-09-04 08:23 KST에 최종 제출하고, 제출 상세에서 `1.0 (10) / 심사 대기 중`을 확인했다. [심사 건](https://appstoreconnect.apple.com/apps/6808099012/distribution/reviewsubmissions/details/6c474e45-34b1-4cfc-aed6-0611f9af356d) ID는 `6c474e45-34b1-4cfc-aed6-0611f9af356d`다.
- 필수 항목 검증 통과: 연령 등급 기본 4+·대한민국 전체 이용가, 무료 가격, 175개 국가·지역의 출시 후 사용 가능 설정. Apple Silicon Mac·Apple Vision Pro에서의 iPhone 앱 제공은 해제했다.
- 심사 승인·일반 공개는 아직 아니다. 접수 완료를 콘텐츠 권한이나 심사 적합성 검증으로 간주하지 않는다.
- 출시 방식: 수동 출시. 심사 통과와 일반 공개는 별도 단계다.
- App Store Connect 저장 확인: 한국어 부제·유틸리티 카테고리, 로그인 불필요·수동 출시, 개인정보 처리방침 URL, 6.9형 스크린샷 2장(상태 → 안내).
- 이전 이름의 제품 설명·프로모션 문구·키워드·지원 URL·저작권·심사 메모와 연락처 저장 및 재접속 후 보존을 확인했다. 연락처 값은 공개 문서에 기록하지 않는다.
- 개인정보 유형·용도·연결·추적 문답은 App Store Connect에서 게시된 상태를 확인했다.
- 새 이름·설명·프로모션 문구·심사 메모 저장과 스크린샷 2장 교체를 완료했다. 빌드 10은 Apple 처리 완료 및 기존 내부 테스터 그룹 연결을 확인하고, App Store 버전 1.0의 제출 빌드로 선택·저장한 뒤 최종 심사에 제출했다.

## 이름 변경 범위

- 표시명: 앱, 홈 화면, 위젯 제목·갤러리, 앱 내 안내, App Store 메타데이터를 `Reset Signal`로 통일한다.
- 제품 설명은 운영자가 GitHub Pages에 발행한 Codex 리셋 참고 지표를 확인하는 기능에 초점을 맞춘다. 개인 계정의 사용량·리셋 여부 조회 기능은 제공하지 않는다.
- 원천인 공개 X 게시물의 분석과 외부 원문 링크를 심사 메모에서 숨기지 않는다. 표시명 변경이 사용 권한 판단을 바꾸지는 않는다.
- 번들 ID·App Group·위젯 kind·Xcode target·저장소·데이터 URL은 호환성을 위해 유지한다. macOS·Windows의 이미 배포된 `0.1.0`은 소급 변경하지 않는다.

## 공개 메타데이터

기본 언어: 한국어 · 카테고리: 유틸리티

이름: `Reset Signal`

부제: `리셋 신호와 근거를 한눈에`

키워드: `위젯,리셋,신호등,상태,개발자,사용량,생산성`

저작권: `2026 sundaynighttt`

지원 URL: https://github.com/sundaynighttt/tibo-reset-signal/issues

마케팅 URL: https://github.com/sundaynighttt/tibo-reset-signal

개인정보 처리방침: [검증된 공개 영구 커밋 URL](https://github.com/sundaynighttt/tibo-reset-signal/blob/a73892e2eb5ef21011b5833139616f52c3350c3f/docs/privacy-policy.md)을 App Store Connect에 저장했다. 새 이름을 반영한 공개 원문 응답 확인 완료.

### 프로모션 텍스트

운영자가 발행한 Codex 리셋 참고 신호를 홈 화면에서 한눈에. 신호 강도와 판정 이유, 확인 시각을 살펴보세요. 계정 연결이나 API 키 설정 없이 시작할 수 있습니다.

### 설명

반복해서 확인하던 리셋 정황을 작은 신호등으로 모았습니다.

Reset Signal은 운영자가 GitHub Pages에 발행한 Codex 리셋 참고 신호를 확인하는 iPhone용 유틸리티입니다. 앱은 공개 상태 파일의 신호·점수·판정 이유·확인 시각을 읽어 보여줍니다. 홈 화면 위젯으로 상태를 살펴보고, 자세한 근거는 앱에서 확인하세요.

주요 기능

- 홈 화면 위젯: 신호 상태, 점수와 최신 판정 근거 표시
- 설명 가능한 신호: 공개된 규칙에 따른 0–10점과 색상·상태명 표시
- 근거 확인: 판정 이유를 보고 외부 원문 링크로 이동
- 새로고침: 앱과 위젯에서 공개된 최신 상태 다시 읽기
- 확인 지연 구분: 오래되거나 실패한 수집 상태를 신호 없음과 별도로 표시
- 운영 상태: 공용 데이터 수집에 사용하는 API 크레딧의 추정 상태 확인

앱 사용에 회원가입, X 로그인, API 키 또는 개인 서버 설정이 필요하지 않습니다. 공용 데이터 수집 비용은 프로젝트 운영자가 부담합니다. 앱 내 구매나 구독은 없습니다.

알아두세요

점수는 규칙 기반 신호 강도이며 통계적인 리셋 확률이 아닙니다. 실제 사용량 리셋을 보장하지 않으며, 개인 계정의 잔여 사용량을 조회하거나 리셋을 실행하지 않습니다. 수집은 약 1시간 간격으로 이루어지며 일정이 지연될 수 있습니다. 위젯 자동 갱신 시각은 iOS가 결정합니다.

운영 수집기는 @thsottiaux의 공개 게시물에서 리셋 관련 정황을 규칙으로 분석합니다. 앱은 X API를 직접 호출하지 않으며 게시물 원문과 이미지를 복제하지 않고 판정 이유와 외부 원문 링크를 제공합니다. OpenAI, X 또는 Tibo가 제공·보증하는 공식 앱이 아닙니다.

## 심사 메모

Reset Signal is a native SwiftUI utility with a WidgetKit Home Screen widget, not a web view. It reads operator-published Codex reset indicators from a public GitHub Pages JSON file. No sign-in, API key, purchase, or subscription is needed. The display name has changed from Tibo Reset Signal; the bundle ID and shared-data endpoint remain unchanged.

Review steps:

1. Launch the app with an internet connection. The main card displays the current signal, score, last successful check, and evidence links when available. A red/no-signal state with no evidence is a valid current result.
2. Tap the top-right refresh button to reload the published status. The shared collector runs about hourly; refreshing does not force a new X API request or guarantee a changed result.
3. Add the small Reset Signal widget from the Home Screen widget gallery. It shares cached signal data with the app and supports refresh.
4. Open “신호 안내 · 개인정보 · 지원” below the main cards to read signal definitions, widget instructions, source limitations, privacy policy, and support links.

The shared collector currently analyzes public posts by @thsottiaux using fixed scoring rules. The iPhone app itself does not call the X API. It displays developer-calculated indicators and reason codes, not copies of third-party post text, photos, or videos. Evidence links open the original X page externally. It is unofficial and does not claim affiliation with or endorsement by OpenAI, X, or Tibo. Scores are heuristic strength, not statistical probabilities, and the app cannot reset or access a user’s Codex account.

“운영 API 크레딧” is an estimate of the project operator’s shared data-collection budget, not the end user’s financial balance. The X Developer Console link is an optional external verification link for the operator; no console login is required to use the app.

## 개인정보·권한 문답 근거

- 로그인·광고·분석 SDK·앱 내 구매·사용자 게시·채팅: 없음.
- App Group의 UserDefaults: 공개 상태 캐시 공유. 앱과 위젯에 `CA92.1`, `1C8F.1` 사용 사유를 포함했다.
- 네트워크: 공개 GitHub Pages JSON의 HTTPS GET. 원문·지원·콘솔은 외부 앱/브라우저로 이동한다.
- 호스팅의 IP/HTTP 접속 기록 처리 가능성을 개인정보 처리방침에 명시했다. 서버 로그를 전혀 수집하지 않는다고 단정하지 않는다.
- App Store Connect 초안은 호스팅의 접속 기록을 보수적으로 `기타 진단 데이터 / 앱 기능 / 사용자에게 연결될 수 있음 / 추적 미사용`으로 분류했다. 수집 전 비식별화가 보장된다는 근거가 없어 비연결로 단정하지 않았다. 이는 앱에 새 분석 SDK나 사용자 프로필 기능을 추가했다는 뜻이 아니다.
- 개인정보 문답은 현재 게시된 상태를 확인했다. 이번 표시명 변경으로 개인정보 처리 방식이나 게시된 문답을 변경하지 않는다.
- 암호화: OS 제공 HTTPS만 사용하며 `ITSAppUsesNonExemptEncryption = false`.
- 콘텐츠 권한 문답은 운영자가 App Store Connect에서 직접 작성·저장했다. 저장 값은 `타사 콘텐츠 포함·표시·이용 없음`이다. 앱이 게시물 원문을 복제하지 않는다는 점과 별개로, 운영 수집기의 공개 X 게시물 분석 및 앱의 외부 원문 링크를 설명·심사 메모에 명시했다. 이 문답의 적용 해석과 필요한 이용 권한이 심사 접수만으로 검증된 것은 아니며, 심사 질의가 오면 실제 동작을 기준으로 재확인한다.

## 스크린샷과 검증 경계

- iPhone 17 Pro Max / iOS 26.5 시뮬레이터 실제 실행 화면, `1320 × 2868` 원본 PNG.
- `dist/app-store-screenshots/01-status.png`: 실데이터의 확인 지연 상태. 마지막 정상 확인이 2시간을 넘은 결과를 숨기거나 합성하지 않았다.
- `dist/app-store-screenshots/02-guide.png`: 실제 앱의 신호 안내 화면.
- 합성 리셋 신호나 가상의 사용자 계정 잔액을 사용하지 않았다.
- 심사 연락처는 공개 저장소에 기록하지 않는다.
- 로컬 검증: XCTest 4개·Python 수집기 테스트 15개·서명 검증·앱과 위젯의 개인정보 사유 plist·릴리스 원장 검사 통과. 앱·위젯의 표시명, 빌드 10, 기존 번들 ID·App Group 유지를 확인했다.
- 시뮬레이터에서 앱·안내 화면과 기존 위젯의 새 제목 레이아웃을 확인했다. 기존 홈 화면 위젯 아래 시스템 이름에는 이전 이름 캐시가 남아 있어, 실기기 업데이트 후 시스템 레이블 갱신은 별도 확인이 필요하다.
- 이전 PR #7의 GitHub CI는 수집기·macOS·Windows·iPhone 모두 통과했다.
- 빌드 10: `ResetSignal-1.0-10.xcarchive` 생성 및 서명 검증 완료. 2026-09-04 06:34 KST에 Xcode의 `Upload succeeded`·`EXPORT SUCCEEDED`를 확인했다. 이후 [TestFlight 빌드 10](https://appstoreconnect.apple.com/teams/8874948e-3fee-4bea-a414-67a4c0f0e7d8/apps/6808099012/testflight/ios/89796342-3823-4991-914a-3ac49fceefa0)의 처리 완료와 제출 버전 연결을 확인했다. 08:23 KST에 App Store 심사 접수까지 완료했으며 승인·일반 공개는 대기한다.
- 코드와 한국어 문서는 PR #7 기반의 [PR #8](https://github.com/sundaynighttt/tibo-reset-signal/pull/8)로 분리했으며 병합 전이다.
