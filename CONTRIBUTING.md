# Contributing

Contributions are welcome through pull requests.

Before submitting:

```bash
python3 -m unittest discover -s tests
swift test --package-path macos
cd ios && xcodegen generate && ./scripts/test-ios.sh
```

Windows changes must also pass:

```powershell
.\windows\test-windows.ps1
```

Do not include live API responses, copied Post text, credentials, cookies, or local cache files in commits. Use synthetic text in scoring tests.
