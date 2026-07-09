# XMONEY End-to-End Testing Guide

Use this when the platform is ready for full manual and automated E2E validation.

## Prerequisites

| Item | Status |
|------|--------|
| Database `smartdms_XMONEY` with schema + seeds | Required |
| Migrations 002 + 003 applied | Required (003 confirmed on `smartdms_XMONEY`) |
| Backend API deployed to `/xmoney/api` | Required — DB-only is not enough for browser/mobile tests |
| `APP_DEBUG=true` on API (staging only) | Required for OTP debug + dev wallet |
| API reachable from browser/mobile | Required |

## API automated tests

```bash
# Read-only smoke test
php backend-api/scripts/smoke-test.php https://qamar.tasjeel.ae/xmoney/api

# Full write flow (register → OTP → wallet → transfer → admin)
php backend-api/scripts/e2e-flow-test.php https://qamar.tasjeel.ae/xmoney/api
```

Set optional env vars:

```bash
XMONEY_API_BASE=https://qamar.tasjeel.ae/xmoney/api
XMONEY_ADMIN_EMAIL=admin@xmoney.local
XMONEY_ADMIN_PASSWORD=your-admin-password
```

## Customer web — manual checklist

1. **Register** → note dev OTP on verify screen (debug mode)
2. **Verify OTP** → account active
3. **Login** → dashboard loads
4. **Wallet** → development deposit OR top-up (auto-capture in debug)
5. **Beneficiaries** → add receiver
6. **KYC** → upload document (optional if KYC not enforced)
7. **Send money** → quote → review → pay with wallet
8. **Receipt** → open from transfer confirmation
9. **Transactions** → filter, paginate, export CSV
10. **Notifications** → mark read
11. **Settings** → theme (light/dark), language (EN/AR/UR), logout

## Admin — manual checklist

1. **Login** → dashboard KPIs + charts
2. **Users** → search, open detail
3. **KYC** → approve/reject uploaded document
4. **Transactions** → filter, update status
5. **Payments** → monitor top-ups
6. **Rates / Fees / Currencies** → update
7. **Reports** → CSV export
8. **Audit logs** → verify entries

## Mobile — manual checklist

> Requires `flutter create .` in `mobile-app/` and branding assets synced.

1. Register → OTP → Login
2. Wallet top-up / settings theme & language
3. Add beneficiary → send money → history
4. KYC upload, notifications, profile

## Runtime configuration

| App | Config file |
|-----|-------------|
| Customer web | `frontend-web/config/runtime-config.js` |
| Admin | `admin-panel/config/runtime-config.js` |
| Mobile | `mobile-app/assets/config.json` |

For local API testing, override in browser console:

```javascript
localStorage.setItem('xm_api_base', 'http://localhost:8080');
localStorage.setItem('xm_admin_access_token', ''); // clear and re-login
```

## Known staging limitations (not blockers for E2E)

- Payment providers are modular placeholders — card flows use `simulate-capture` in debug
- SMS/email OTP delivered via logs when `MAIL_DRIVER=log` / `SMS_DRIVER=log`
- Real Stripe/Twilio integrations require business approval before production

## Ready for full E2E when

- [ ] `smoke-test.php` — all checks pass
- [ ] `e2e-flow-test.php` — all steps pass against target API
- [ ] Customer web checklist completed
- [ ] Admin checklist completed
- [ ] Mobile builds and runs on at least one device/emulator
