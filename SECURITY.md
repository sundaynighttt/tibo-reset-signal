# 보안 정책 / Security Policy

## 제보 방법

API 키, 액세스 토큰, 쿠키, 서명 인증서 또는 비공개 사용자 데이터가 포함된 공개 이슈를 만들지 마세요. 가능하면 GitHub의 비공개 취약점 제보 기능으로 알려주세요.

## 데이터 경계

- 최종 사용자 앱은 공개 `latest.json` 문서만 요청합니다.
- 운영자의 X API 토큰은 Actions Secret인 `X_BEARER_TOKEN`에만 저장합니다.
- Pull Request로 실행되는 워크플로에는 수집기 Secret을 전달하지 않습니다.
- 공개 산출물에는 X API 응답이나 포스트 원문 전체가 포함되면 안 됩니다.
- 공개 크레딧 값은 운영자가 입력한 기준 잔액과 과금 리소스 수로 계산한 로컬 추정치이며, Developer Console이 반환한 실제 잔액이 아닙니다.

Secret이 노출됐다면 애플리케이션 코드를 조사하기 전에 먼저 폐기하세요.

## English summary

Never disclose credentials or private user data in a public issue. End-user apps read only the public `latest.json`; the maintainer token stays in GitHub Actions Secrets, pull-request workflows do not receive it, and public output excludes raw API responses and full post text. The displayed API-credit value is an estimate, not an official Developer Console balance. Revoke any exposed secret before investigating the code.
