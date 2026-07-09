# XMONEY — Deploy When Authorized

**Status:** Database `smartdms_XMONEY` is up to date (migration 003 confirmed). Application code is on GitHub `main`. **Do not deploy until you authorize** — per project policy during development.

## What deploy unlocks

Until the API is uploaded to `/home/smartdms/public_html/`, browser and mobile clients cannot complete E2E tests against `https://qamar.tasjeel.ae/api` (health endpoint currently unavailable).

## When you are ready

1. Confirm GitHub Secrets for workflow `Deploy XMONEY` (see `.github/workflows/deploy-xmoney.yml` header).
2. Run workflow **Deploy XMONEY** manually (`workflow_dispatch`) — auto-deploy on push is disabled.
3. After upload, verify:
   ```bash
   curl https://qamar.tasjeel.ae/api/v1/health
   php backend-api/scripts/smoke-test.php https://qamar.tasjeel.ae/api
   ```
4. For **staging E2E** (OTP debug + dev wallet deposit), use `config/env.staging.example` as the basis for server `api/.env` (`APP_DEBUG=true`). Switch to production values (`APP_DEBUG=false`) only for go-live.

## Staging vs production

| Setting | Staging E2E | Production |
|---------|-------------|------------|
| `APP_DEBUG` | `true` | `false` |
| OTP in API response | Yes | No |
| `POST /v1/wallet/deposit` | Yes | No |
| Payment/SMS providers | Stub/log | Real (business decision) |

## Isolation guarantees

- FTP target: `/home/smartdms/public_html/` only
- Database: `smartdms_XMONEY` only
- Workflow fails if the path is not exactly `/home/smartdms/public_html/` (or `/public_html/`) or if the DB name is not exactly `smartdms_XMONEY`

See `documentation/E2E_TESTING.md` for the full test checklist after deploy.
