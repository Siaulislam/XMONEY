# XMONEY Mobile Application

Cross-platform mobile foundation for Android and iOS.

## Recommended stack (production path)

| Layer | Choice | Notes |
|-------|--------|-------|
| Shared UI / logic | **Flutter** or **React Native** | Single codebase → Android + iOS |
| Native folders | `android/` · `ios/` | Platform projects / wrappers |
| API | XMONEY Backend (`/api/v1/*`) | Same JWT auth as web |

This repository currently scaffolds the **native project folders** and a **shared API contract** so either Flutter or React Native can be initialized without redesigning the backend.

## Shared modules (`shared/`)

- `api-contract.md` — endpoint map for mobile clients
- `config.example.json` — environment endpoints

## Next steps to generate full native apps

### Option A — Flutter (recommended for fintech)

```bash
cd C:\XMONEY\mobile-app
flutter create --org com.xmoney --project-name xmoney_app .
# Move generated android/ ios/ into place if needed
```

### Option B — React Native

```bash
cd C:\XMONEY\mobile-app
npx @react-native-community/cli init XMoneyApp
```

## Feature parity with web

1. Auth (register, OTP, login, logout, forgot password)
2. Profile & device management
3. KYC document upload (camera + gallery)
4. Beneficiaries CRUD
5. Transfer quote → create → confirm
6. Wallet balance & history
7. Push notifications (FCM / APNs)

## Security notes

- Store JWT refresh tokens in Keychain (iOS) / EncryptedSharedPreferences (Android)
- Certificate pinning recommended before production
- Biometric unlock optional for returning sessions
