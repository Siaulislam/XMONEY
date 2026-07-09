# XMONEY Mobile API Contract

Base URL (local): `http://10.0.2.2:8080/api` (Android emulator) or machine LAN IP for devices.

All authenticated requests:

```
Authorization: Bearer <access_token>
Content-Type: application/json
X-Device-Id: <stable-device-uuid>
```

## Auth
| Method | Path | Notes |
|--------|------|-------|
| POST | `/v1/auth/register` | Returns OTP challenge |
| POST | `/v1/auth/verify-otp` | Activate account |
| POST | `/v1/auth/login` | Returns access + refresh tokens |
| POST | `/v1/auth/logout` | Revoke refresh |
| POST | `/v1/auth/forgot-password` | OTP |
| POST | `/v1/auth/reset-password` | OTP + new password |

## Customer
| Method | Path |
|--------|------|
| GET/PUT | `/v1/me` |
| POST | `/v1/me/change-password` |
| GET | `/v1/me/devices` |
| DELETE | `/v1/me/devices/{id}` |
| GET/POST | `/v1/kyc`, `/v1/kyc/upload` |
| CRUD | `/v1/beneficiaries` |
| GET | `/v1/currencies`, `/v1/rates` |
| POST | `/v1/transfers/quote` |
| CRUD flow | `/v1/transfers` |
| GET | `/v1/wallet`, `/v1/wallet/history` |

## Status enums (mobile UI badges)
- KYC: `none | pending | approved | rejected | expired`
- Transfer: `created | pending_payment | processing | under_review | completed | failed | cancelled | refunded`
