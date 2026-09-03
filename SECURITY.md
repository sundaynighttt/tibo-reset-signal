# Security Policy

## Reporting

Do not open a public issue containing API keys, access tokens, cookies, signing certificates, or private user data. Report a vulnerability through GitHub's private vulnerability reporting feature when available.

## Data boundary

- End-user apps only request the public `latest.json` document.
- The maintainer X API token belongs only in the `X_BEARER_TOKEN` Actions Secret.
- Workflows triggered by pull requests never receive the collector secret.
- Public output must not contain X API responses or full Post text.

If a secret is exposed, revoke it before investigating the application code.
