# XMONEY — GitHub Secrets & Deploy Validation

## Approved production targets (this hosting)

| Setting | Exact value |
|---------|-------------|
| **FTP_REMOTE_PATH** | `/home/smartdms/public_html/` |
| **Public site** | `https://smartdms.me/` |
| **XMONEY_APP_URL** | `https://smartdms.me/api` |
| **XMONEY_DB_HOST** | `localhost` |
| **XMONEY_DB_NAME** | `smartdms_XMONEY` |
| **XMONEY_DB_USER** | `smartdms_xmoney` |

### Blocked paths (workflow refuses)

- `/` (account root)
- `/home/smartdms/smartdms.me` (addon domain folder — not the deploy target)
- Any path that is not the approved `public_html` root

---

## Required secrets (exact names)

| Secret | Expected value |
|--------|----------------|
| `FTP_HOST` | FTP hostname |
| `FTP_PORT` | `21` |
| `FTP_USERNAME` | FTP user for XMONEY (or account with access only as needed) |
| `FTP_PASSWORD` | FTP password |
| `FTP_REMOTE_PATH` | `/home/smartdms/public_html/` |
| `XMONEY_DB_HOST` | `localhost` |
| `XMONEY_DB_NAME` | `smartdms_XMONEY` |
| `XMONEY_DB_USER` | `smartdms_xmoney` |
| `XMONEY_DB_PASS` | XMONEY DB password |
| `XMONEY_JWT_SECRET` | 32+ random characters |
| `XMONEY_APP_URL` | `https://smartdms.me/api` |

## Optional secrets (OTP email)

| Secret | Default if omitted |
|--------|-------------------|
| `XMONEY_SMTP_HOST` | `mail.smartdms.me` |
| `XMONEY_SMTP_PORT` | `465` |
| `XMONEY_SMTP_SECURE` | `ssl` |
| `XMONEY_SMTP_USER` | `xmoney@smartdms.me` |
| `XMONEY_SMTP_PASS` | *(required for real email — without it deploy uses `MAIL_DRIVER=log`)* |
| `XMONEY_MAIL_FROM_ADDRESS` | `xmoney@smartdms.me` |
| `XMONEY_MAIL_FROM_NAME` | `XMONEY` |

---

## Auto deploy

- Every **push to `main`** triggers **Deploy XMONEY** and uploads to `public_html/` via FTP.
- No workflow approval step is configured in the YAML — deploy runs immediately when secrets are set.
- If jobs still show **Pending** waiting for approval, disable **Settings → Environments → Required reviewers** in GitHub (repo/org setting, not in code).

## Manual deploy (optional)

1. GitHub → **Actions** → **Build cPanel Package** → **Run workflow**
2. Download artifact `xmoney-cpanel-package.zip`
3. Extract into `public_html/` (must include `api/vendor/`)
4. Create `public_html/api/.env` from `api/.env.example` with DB, JWT, and SMTP values
5. Test `https://smartdms.me/api/v1/health` → must return JSON `200`

---

## Safety

- Deploys **only** into `public_html/`
- Uses database `smartdms_XMONEY` only
- `dangerous-clean-slate: false`
- Deploy workflow bundles `api/vendor/` automatically (no server Composer required)
