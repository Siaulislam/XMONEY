# XMONEY Mobile App Setup

**Location:** `C:\XMONEY\mobile-app`

Web development is paused unless needed for API/backend. **Mobile is the primary focus.**

## No Android Studio? Use GitHub Actions

Every push to `main` that changes `mobile-app/` builds a **debug APK** automatically.

1. GitHub → **Actions** → **Mobile Debug APK**
2. Open the latest green run
3. Download artifact **`XMONEY-Debug-APK`**
4. Copy `app-debug.apk` to your phone and install (enable “Install unknown apps”)

Manual builds:
- **Mobile Release APK** — release APK artifact
- **Mobile Release AAB** — Play Store bundle (for later)

## Local development (optional)

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.16+
- Android Studio and/or Xcode for emulators

```bash
cd mobile-app
flutter create . --org com.smartdms.xmoney --project-name xmoney_app --platforms=android,ios
bash scripts/ci-prepare.sh   # or: flutter pub get
flutter run
```

Sync branding from repo root (Windows):

```powershell
.\scripts\sync-branding-to-mobile.ps1
.\scripts\sync-i18n-to-mobile.ps1
```

## Configuration

`assets/config.json`:

```json
{ "apiBaseUrl": "https://smartdms.me/api" }
```

## Module roadmap

See `documentation/MOBILE_ROADMAP.md` for completion status per screen.

## E2E on device

Requires API deployed with valid `api/.env` and DB. For OTP testing during development, API `APP_DEBUG=true` returns debug OTP in responses.
