# iPhone App Store 제출 자료

## 대상과 현재 상태

- 앱: Tibo Reset Signal · Apple ID `6808099012`
- 번들: `com.sundaynighttt.tiboresetsignal.ios`
- 버전: `1.0 (9)` · iPhone 전용 · iOS 17 이상
- 배포용 archive와 서명 검증 완료, 2026-09-04 KST App Store Connect 업로드 성공.
- 심사 요청 전. 업로드 성공을 처리 완료·심사 제출·승인으로 간주하지 않는다.
- 미확정: 심사 연락처(이름·성·전화번호·이메일), 타사 콘텐츠 이용 권한 선언, 개인정보 답변 게시에 수반되는 정확성·법 준수·변경 시 갱신 동의.
- 출시 방식: 수동 출시. 심사 통과와 일반 공개는 별도 단계다.
- App Store Connect 저장 확인: 한국어 부제·유틸리티 카테고리, 로그인 불필요·수동 출시, 개인정보 처리방침 URL, 6.9형 스크린샷 2장(상태 → 안내).
- 제품 설명·프로모션 문구·키워드·지원 URL·저작권·심사 메모는 입력했으나 빈 심사 연락처가 저장 검증을 막는다. 브라우저 초안과 아래 원문을 보존했다.
- 개인정보 유형·용도·연결·추적 문답은 작성했으나 게시 동의 전이다.
- 확인 답변 수신 후 연령 등급·무료 가격과 배포 지역·새 빌드 선택·전체 필수 항목 검증을 마무리하고 심사에 제출한다.

## 공개 메타데이터

기본 언어: 한국어 · 카테고리: 유틸리티

이름: `Tibo Reset Signal`

부제: `리셋 신호와 근거를 한눈에`

키워드: `위젯,리셋,신호등,상태,개발자,사용량,생산성`

저작권: `2026 sundaynighttt`

지원 URL: https://github.com/sundaynighttt/tibo-reset-signal/issues

마케팅 URL: https://github.com/sundaynighttt/tibo-reset-signal

개인정보 처리방침: [검증된 공개 영구 커밋 URL](https://github.com/sundaynighttt/tibo-reset-signal/blob/48daed37c4820f94902bace67e6cb58596059cfd/docs/privacy-policy.md)을 App Store Connect에 저장했다. HTTP 200 및 공개 원문 확인 완료.

### 프로모션 텍스트

리셋 신호를 홈 화면에서 한눈에. 신호 강도와 최신 판정 근거를 확인하고, 필요할 때 원문으로 이어 보세요. 계정 연결이나 API 키 설정 없이 시작할 수 있습니다.

### 설명

반복해서 확인하던 리셋 정황을 작은 신호등으로 모았습니다.

Tibo Reset Signal은 공개된 Codex 리셋 관련 정황을 신호와 점수로 정리하는 iPhone용 유틸리티입니다. 홈 화면 위젯에서 상태를 확인하고, 앱에서 판정 이유와 마지막 확인 시각을 함께 살펴보세요.

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

이 앱은 @thsottiaux의 공개 게시물에서 리셋 관련 정황을 분석합니다. 게시물 원문과 이미지를 앱에 복제하지 않고 판정 이유와 외부 원문 링크를 제공합니다. OpenAI, X 또는 Tibo가 제공·보증하는 공식 앱이 아닙니다.

## 심사 메모

This is a native SwiftUI utility with a WidgetKit Home Screen widget, not a web view. No sign-in, API key, purchase, or subscription is needed.

Review steps:

1. Launch the app with an internet connection. The main card displays the current signal, score, last successful check, and evidence links when available. A red/no-signal state with no evidence is a valid current result.
2. Tap the top-right refresh button to reload the published status. The shared collector runs about hourly; refreshing does not force a new X API request or guarantee a changed result.
3. Add the small Tibo Reset Signal widget from the Home Screen widget gallery. It shares cached signal data with the app and supports refresh.
4. Open “신호 안내 · 개인정보 · 지원” below the main cards to read signal definitions, widget instructions, source limitations, privacy policy, and support links.

The app displays developer-calculated indicators and reason codes, not copies of third-party post text, photos, or videos. Evidence links open the original X page externally. It is unofficial and does not claim affiliation with or endorsement by OpenAI, X, or Tibo. Scores are heuristic strength, not statistical probabilities, and the app cannot reset or access a user’s Codex account.

“운영 API 크레딧” is an estimate of the project operator’s shared data-collection budget, not the end user’s financial balance. The X Developer Console link is an optional external verification link for the operator; no console login is required to use the app.

## 개인정보·권한 문답 근거

- 로그인·광고·분석 SDK·앱 내 구매·사용자 게시·채팅: 없음.
- App Group의 UserDefaults: 공개 상태 캐시 공유. 앱과 위젯에 `CA92.1`, `1C8F.1` 사용 사유를 포함했다.
- 네트워크: 공개 GitHub Pages JSON의 HTTPS GET. 원문·지원·콘솔은 외부 앱/브라우저로 이동한다.
- 호스팅의 IP/HTTP 접속 기록 처리 가능성을 개인정보 처리방침에 명시했다. 서버 로그를 전혀 수집하지 않는다고 단정하지 않는다.
- App Store Connect 초안은 호스팅의 접속 기록을 보수적으로 `기타 진단 데이터 / 앱 기능 / 사용자에게 연결될 수 있음 / 추적 미사용`으로 분류했다. 수집 전 비식별화가 보장된다는 근거가 없어 비연결로 단정하지 않았다. 이는 앱에 새 분석 SDK나 사용자 프로필 기능을 추가했다는 뜻이 아니다.
- 개인정보 문답 게시 시 Apple이 정확성·법 준수·변경 시 갱신 동의를 요구하므로 운영자 확인 전 게시하지 않았다.
- 암호화: OS 제공 HTTPS만 사용하며 `ITSAppUsesNonExemptEncryption = false`.
- 콘텐츠 권한: Apple은 타사 콘텐츠에 접근하는 앱도 권한 확인을 요구한다. 원문 링크가 있으므로 ‘타사 콘텐츠 없음’으로 우회하지 않는다. 운영자의 권한 확인 없이 권한 보유를 선언하지 않는다.

## 스크린샷과 검증 경계

- iPhone 17 Pro Max / iOS 26.5 시뮬레이터 실제 실행 화면, `1320 × 2868` 원본 PNG.
- `dist/app-store-screenshots/01-status.png`: 실데이터의 신호 없음 상태.
- `dist/app-store-screenshots/02-guide.png`: 실제 앱의 신호 안내 화면.
- 합성 리셋 신호나 가상의 사용자 계정 잔액을 사용하지 않았다.
- 심사 연락처는 공개 저장소에 기록하지 않는다.
- 로컬 검증: XCTest 3개·Python 수집기 테스트 15개·서명 검증·개인정보 사유 plist 검사·릴리스 원장 검사 통과.
- PR #7의 GitHub CI에서 수집기·macOS·Windows 검사는 통과했으며 iPhone 검사는 마지막 확인 시 실행 중이었다.
