# XMONEY — Provider Architecture

XMONEY uses **configuration-only provider selection**. No payment gateway or SMS provider is hard-coded in business logic.

## Design principles

1. **Interface first** — All external integrations implement a provider interface.
2. **Registry resolution** — `PaymentProviderRegistry` and `NotificationProviderRegistry` map env config → provider class.
3. **Graceful fallback** — Unconfigured providers delegate to stub/log drivers (development-safe).
4. **Future-ready** — When credentials are set but code is not yet implemented, providers throw a clear error (no silent failure).

---

## Payment providers

| Config value | Class | Required env vars |
|--------------|-------|-------------------|
| `stub` (default) | `StubPaymentProvider` | — |
| `stripe` | `StripePaymentProvider` | `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` |
| `checkout` | `CheckoutPaymentProvider` | `CHECKOUT_SECRET_KEY`, `CHECKOUT_WEBHOOK_SECRET` |
| `wise` | `WisePaymentProvider` | `WISE_API_TOKEN`, `WISE_PROFILE_ID` |
| `uae_bank` | `UaeBankPaymentProvider` | `UAE_BANK_API_URL`, `UAE_BANK_CLIENT_ID`, `UAE_BANK_CLIENT_SECRET` |

**Set in `.env`:**

```env
PAYMENT_DEFAULT_PROVIDER=stub
```

**Service:** `PaymentService::resolve()`  
**Webhook endpoint:** `POST /v1/webhooks/payments/{provider}`  
**Status API:** `GET /v1/payments/{uuid}`  
**Dev simulation:** `POST /v1/payments/{uuid}/simulate-capture` (APP_DEBUG only)

### Adding a new payment provider

1. Create `backend-api/src/Providers/Payment/YourProvider.php` implementing `PaymentProviderInterface`.
2. Register in `PaymentProviderRegistry::MAP`.
3. Add env vars to `backend-api/.env.example`.
4. Implement webhook signature verification in `WebhookController` when ready.

---

## Notification / OTP providers

| Channel | Config key | Drivers |
|---------|------------|---------|
| Email | `MAIL_DRIVER` | `log`, `smtp` |
| SMS / OTP | `SMS_DRIVER` | `log`, `twilio`, `aws_sns`, `uae_sms` |
| Push | `PUSH_DRIVER` | `log`, `fcm`, `apns` |

**Interfaces:** `NotificationProviderInterface`  
**Registry:** `NotificationProviderRegistry::forChannel('email'|'sms'|'push'|'in_app')`

### SMS placeholder providers

| Driver | Env vars |
|--------|----------|
| `twilio` | `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_NUMBER` |
| `aws_sns` | `AWS_SNS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` |
| `uae_sms` | `UAE_SMS_API_URL`, `UAE_SMS_API_KEY`, `UAE_SMS_SENDER_ID` |

OTP delivery uses the same notification layer via `OtpService` → `NotificationService::sendOtp()`.

### Adding a new SMS provider

1. Extend `AbstractPlaceholderSmsProvider` or implement `NotificationProviderInterface`.
2. Register in `NotificationProviderRegistry::SMS`.
3. Set `SMS_DRIVER=your_driver` in `.env`.

---

## Exchange rate providers

| Config | Behavior |
|--------|----------|
| `EXCHANGE_PROVIDER=manual` | DB rates only (default) |
| `EXCHANGE_API_URL` set | `ExternalApiExchangeProvider` (Frankfurter-compatible) |

---

## Current development mode

- **Payments:** Stub provider simulates initiate/capture; card/gateway transfers use `simulate-capture` in debug.
- **SMS:** Log driver writes OTP to `logs/notifications.log` (debug API may expose `debug_otp`).
- **Email:** Log or SMTP when configured.

No real money movement or SMS charges occur until production providers are configured and implemented.
