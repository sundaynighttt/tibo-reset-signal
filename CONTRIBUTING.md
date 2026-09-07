# 기여 안내 / Contributing

Pull Request를 통한 기여를 환영합니다. 아래 검증을 먼저 통과해 주세요.

macOS·iPhone·수집기:

```bash
python3 -m unittest discover -s tests
swift test --package-path macos
cd ios && xcodegen generate && ./scripts/test-ios.sh
```

Windows 변경은 다음 검사도 통과해야 합니다.

```powershell
.\windows\test-windows.ps1
```

실제 API 응답, 복사한 포스트 원문, 인증정보, 쿠키 또는 로컬 캐시 파일을 커밋하지 마세요. 점수 규칙 테스트에는 합성 문장만 사용합니다.

## English summary

Pull requests are welcome. Run the checks above before submitting. Never commit live API responses, copied post text, credentials, cookies, or local cache files; use synthetic text in scoring tests.
