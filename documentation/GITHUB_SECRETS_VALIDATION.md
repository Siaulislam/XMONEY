# XMONEY — GitHub Secrets & Deploy Validation

## Approved production targets (this hosting)

| Setting | Exact value |
|---------|-------------|
| **FTP_REMOTE_PATH** | `/home/smartdms/public_html/` |
| **Public site** | `https://qamar.tasjeel.ae/` |
| **XMONEY_APP_URL** | `https://qamar.tasjeel.ae/api` |
| **XMONEY_DB_HOST** | `localhost` |
| **XMONEY_DB_NAME** | `smartdms_XMONEY` |
| **XMONEY_DB_USER** | `smartdms_xmoney` |

### Blocked paths (workflow refuses)

- `/home/smartdms/public_html` (main site root)
- `/public_html`
- `/home/smartdms/smartdms.me`
- Any path whose last folder is not lowercase `xmoney`

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
| `XMONEY_APP_URL` | `https://qamar.tasjeel.ae/api` |

---

## Safety

- Deploys **only** into `public_html/`
- Never syncs or cleans `public_html/` root
- Uses database `smartdms_XMONEY` only
- `dangerous-clean-slate: false`
