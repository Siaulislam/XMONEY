# XMONEY — Module Roadmap

| Module | Status | Notes |
|--------|--------|-------|
| Project structure | Done | Isolated cPanel-ready layout |
| Database schema | Done | Full relational model + cPanel SQL pack |
| **Authentication** | **Done** | Register, OTP, resend, login, refresh, logout, lockout, devices, rate limits |
| **User dashboard** | **Done** | Overview, profile, beneficiaries, wallet, transactions, notifications, settings, KYC |
| **Money transfer flow** | **Done** | Beneficiary → amount → quote → review → pay → receipt |
| **Admin dashboard** | **Done** | Users, KYC, transactions, rates, fees, currencies, reports, audit logs, settings |
| Platform settings API | Done | Transfer limits, security, notifications |
| Admin user detail / unblock | Done | API + admin UI |
| SMTP notification driver | Done | Falls back to log when SMTP not configured |
| Payment provider layer | Done (stub) | Ready for bank/card/gateway adapters |
| FX engine | Done | Market − margin = customer rate |
| Wallet ledger | Done | Optimistic locking + history |
| Mobile structure | Scaffolded | Shared API contract |
| Live FX API | Next | External provider |
| Live payment gateway | Next | Real provider |
| SMTP / SMS / Push | Next | Replace log drivers |
| Flutter/RN apps | Next | Generate from scaffold |
| cPanel production deploy | Waiting | Needs hosting credentials |

## Recently completed (this iteration)

### Authentication
- Refresh token rotation (`POST /v1/auth/refresh`)
- Logout without requiring valid access JWT
- Account lockout enforcement
- Block login for `pending` (unverified) users
- Device registration on login (`X-Device-Id`)
- Resend OTP + cooldown UI
- Rate limiting on auth routes
- Session revoke on password change/reset
- Frontend silent refresh interceptor

### Customer app
- Shared shell (`shell.js`) with session bootstrap via `/v1/me`
- Notifications inbox (API + UI)
- Settings preferences
- Multi-step transfer wizard + receipt with status history

### Admin
- Fees CRUD API + UI
- Currency enable/disable
- Audit log viewer
- Admin refresh + logout

## Next engineering priorities

1. Install local PHP/Composer/MySQL and run smoke tests
2. SMTP mail driver for real OTP delivery
3. Harden transfer limits from `settings` table — **Done**
4. Admin user detail / unblock / KYC history views — **Done**
5. Mobile app generation (Flutter)
