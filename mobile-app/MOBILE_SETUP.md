# XMONEY Mobile App Setup

**Location:** `C:\XMONEY\mobile-app`

**Mobile is the primary focus.** A **web preview** is built automatically for quick browser testing.

## Web preview (no install needed)

Every push to `main` that changes `mobile-app/` builds and deploys Flutter Web to GitHub Pages.

**Preview URL:** [https://siaulislam.github.io/XMONEY/](https://siaulislam.github.io/XMONEY/)

1. GitHub → **Actions** → **Mobile Web Preview** → latest green run
2. Open the job summary — the **Preview URL** is listed at the top
3. First-time setup: repo **Settings → Pages → Build and deployment → GitHub Actions**

The preview calls `https://smartdms.me/api`. Production `.env` must include `https://siaulislam.github.io` in `CORS_ALLOWED_ORIGINS` (added automatically on the next API deploy).

### Dev login (OTP bypass — staging/development only)

While `APP_ENV` is **not** `production` (deploy defaults to `staging` during active development):

| Field | Value |
|-------|-------|
| Email | `ziassp91@gmai.com` |
| Password | `123456` |

No OTP required. Set GitHub secrets `XMONEY_APP_ENV=production` and `XMONEY_APP_DEBUG=false` before go-live.

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
flutter create . --org com.smartdms.xmoney --project-name xmoney_app --platforms=android,ios,web
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
