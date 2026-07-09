# XMONEY — API Reference (v1)

Base path: `/v1` (local) or `/api/v1` (cPanel)

## Public

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health + DB check |
| POST | `/auth/register` | Register customer (issues OTP) |
| POST | `/auth/verify-otp` | Verify OTP (`registration`, `password_reset`, …) |
| POST | `/auth/resend-otp` | Resend OTP (rate limited) |
| POST | `/auth/login` | Customer login (JWT + refresh + device bind) |
| POST | `/auth/refresh` | Rotate refresh → new access + refresh |
| POST | `/auth/logout` | Revoke refresh token (no access JWT required) |
| POST | `/auth/forgot-password` | Request password-reset OTP |
| POST | `/auth/reset-password` | Reset password + revoke all sessions |
| GET | `/currencies` | Active currencies |
| GET | `/rates` | Active customer rates |
| GET | `/settings/public` | Transfer limits + public platform settings |
| POST | `/webhooks/payments/{provider}` | Payment provider webhooks (stub + future gateways) |
| POST | `/admin/auth/login` | Staff login |
| POST | `/admin/auth/logout` | Staff logout |
| POST | `/admin/auth/refresh` | Staff token refresh |

## Customer (Bearer JWT)

| Method | Endpoint |
|--------|----------|
| GET/PUT | `/me` |
| POST | `/me/change-password` |
| GET/DELETE | `/me/devices`, `/me/devices/{id}` |
| GET | `/notifications` |
| POST | `/notifications/{uuid}/read` |
| POST | `/notifications/read-all` |
| GET/POST | `/kyc`, `/kyc/upload` |
| CRUD | `/beneficiaries`… |
| POST | `/transfers/quote` |
| GET/POST | `/transfers` |
| GET/POST | `/transfers/{uuid}`, `…/confirm`, `…/cancel` |
| GET | `/payments/{uuid}` |
| POST | `/payments/{uuid}/simulate-capture` | Development only (`APP_DEBUG`) |
| GET/POST | `/wallet`, `/wallets`, `/wallet/history`, `/wallet/top-up`, `/wallet/deposit` |
| GET | `/analytics/summary` |

## Admin (Bearer admin JWT)

| Method | Endpoint |
|--------|----------|
| GET | `/admin/analytics` |
| GET | `/admin/payments` |
| GET | `/admin/dashboard` |
| GET | `/admin/users` |
| GET | `/admin/users/{uuid}` |
| POST | `/admin/users/{uuid}/block` |
| POST | `/admin/users/{uuid}/unblock` |
| GET | `/admin/kyc/pending` |
| GET | `/admin/kyc/{uuid}/file` |
| POST | `/admin/kyc/{uuid}/review` |
| GET | `/admin/transactions` |
| POST | `/admin/transactions/{uuid}/status` |
| POST | `/admin/rates` |
| GET/POST | `/admin/fees` |
| GET/PATCH | `/admin/currencies`, `/admin/currencies/{code}` |
| GET | `/admin/reports?type=daily\|monthly\|revenue\|failed` |
| GET | `/admin/audit-logs` |
| GET/PUT | `/admin/settings` |

Provider configuration: see [PROVIDERS.md](./PROVIDERS.md).

## Auth headers

```
Authorization: Bearer <access_token>
X-Device-Id: <stable-device-uuid>
Content-Type: application/json
```

## Response shape

```json
{
  "success": true,
  "message": "OK",
  "data": {},
  "request_id": "…"
}
```

## Security notes

- Access JWT TTL: `JWT_ACCESS_TTL_MINUTES` (default 15)
- Refresh tokens hashed at rest; rotated on `/auth/refresh`
- Failed logins lock account after `SECURITY_MAX_LOGIN_ATTEMPTS`
- Auth endpoints rate-limited via `RateLimitMiddleware`
- Password change/reset revokes all refresh tokens
