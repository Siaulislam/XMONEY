# XMONEY Flutter Mobile App

Professional Android & iOS client for the XMONEY platform.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.16+
- Android Studio / Xcode for device builds

## First-time setup

The Dart source is included. Generate native platform folders once:

```bash
cd mobile-app
flutter create --org com.xmoney --project-name xmoney_app .
```

This merges Android/iOS projects with the existing `lib/` code. If prompted to overwrite `lib/main.dart`, **keep the existing XMONEY files**.

Install dependencies:

```bash
flutter pub get
```

Configure API URL in `assets/config.json`:

```json
{
  "apiBaseUrl": "https://qamar.tasjeel.ae/xmoney/api"
}
```

## Run

```bash
# Android emulator / device
flutter run

# iOS simulator (macOS only)
flutter run -d ios

# Release APK
flutter build apk --release

# iOS archive (macOS + Xcode)
flutter build ios --release
```

## Features

| Screen | API |
|--------|-----|
| Login | `POST /v1/auth/login` |
| Dashboard | `/v1/analytics/summary`, `/v1/transfers` |
| Wallet | `/v1/wallet`, `/v1/wallet/top-up`, `/v1/wallet/history` |
| Send money | `/v1/beneficiaries`, `/v1/transfers/quote`, `/v1/transfers` |
| Transactions | `/v1/transfers` |
| Profile | `/v1/me`, logout |

## Security

- Tokens stored in `flutter_secure_storage` (Keychain / EncryptedSharedPreferences)
- Stable device UUID sent as `X-Device-Id`
- Silent refresh on 401
