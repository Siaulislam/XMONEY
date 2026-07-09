# XMONEY Mobile App Setup

The Flutter source lives in `mobile-app/` but native `android/` and `ios/` folders are generated on your machine.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.16+
- Android Studio and/or Xcode for device builds

## First-time bootstrap

```bash
cd mobile-app
flutter create . --org ae.tasjeel.xmoney --project-name xmoney
flutter pub get
```

Copy launcher icons from the repo branding pack:

```powershell
# From repo root (Windows)
.\scripts\sync-branding-to-mobile.ps1
.\scripts\sync-i18n-to-mobile.ps1
```

Then replace default Flutter icons with files under `assets/android/` and `assets/ios/` per Flutter launcher icon docs, or use `flutter_launcher_icons` if added later.

## Configuration

`assets/config.json` points at the API base URL (default production staging):

```json
{ "apiBaseUrl": "https://qamar.tasjeel.ae/api" }
```

For local API testing, edit before `flutter run`.

## Run

```bash
flutter run
```

## Implemented screens

- Auth: login, register, OTP, forgot password
- Wallet with dev deposit when API `development_mode` is true
- Transfer with balance guard
- Transactions list + detail (status history, cancel)
- Profile view + edit (`PUT /v1/me`)
- KYC, beneficiaries, notifications, settings (theme/locale)

## E2E on device

Requires API deployed with `APP_DEBUG=true` for OTP debug and wallet deposit. See `documentation/E2E_TESTING.md`.
