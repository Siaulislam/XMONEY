# XMONEY — Authentication Module

Production authentication for customers and staff.

## Flows

### Registration
1. `POST /v1/auth/register` → user `pending`, profile + AED wallet created
2. OTP emailed (logged in local/dev)
3. `POST /v1/auth/verify-otp` purpose=`registration` → status `active`

### Production OTP email
- Configure SMTP in `public_html/api/.env`
- Recommended mailbox for this hosting: `xmoney@smartdms.me`
- Recommended SMTP:
  - `MAIL_DRIVER=smtp`
  - `SMTP_HOST=mail.smartdms.me`
  - `SMTP_PORT=465`
  - `SMTP_SECURE=ssl`
  - `SMTP_USER=xmoney@smartdms.me`
  - `SMTP_PASS=<server-only secret>`
  - `MAIL_FROM_ADDRESS=xmoney@smartdms.me`
  - `MAIL_FROM_NAME=XMONEY`

### Login
1. Lock check → password verify → reject `pending` / blocked statuses
2. Reset failed-login counter
3. Register/update `user_devices`
4. Issue access JWT + hashed refresh token bound to device

### Session continuity
1. Access token expires (default 15 min)
2. Frontend calls `POST /v1/auth/refresh` with refresh token
3. Old refresh revoked; new pair issued (rotation)

### Logout
- `POST /v1/auth/logout` with `{ refresh_token }` — **no access JWT required**
- Revokes server-side refresh token

### Password reset
1. `forgot-password` → OTP
2. `reset-password` → new hash + **revoke all refresh tokens**

### Change password (authenticated)
- Verifies current password
- Updates hash
- Revokes all sessions (forces re-login)

## Security controls

| Control | Implementation |
|---------|----------------|
| Password hashing | bcrypt cost 12 |
| Refresh storage | SHA-256 hash only |
| OTP storage | SHA-256 hash; prior OTPs invalidated on resend |
| Lockout | `SECURITY_MAX_LOGIN_ATTEMPTS` / `SECURITY_LOCKOUT_MINUTES` |
| Rate limit | File-backed per IP+action |
| Device binding | `user_devices` + `refresh_tokens.device_id` |
| Audit | `audit_logs` on register/login/logout/password/device |

## Frontend

- `frontend-web/src/assets/js/api.js` — refresh interceptor, device UUID, toasts
- Pages: `login`, `register`, `verify-otp`, `forgot-password`, `profile`, `settings`
