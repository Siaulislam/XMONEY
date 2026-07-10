# XMONEY Mobile — Development Roadmap

**Primary focus:** Flutter mobile app (Android + iOS single codebase).  
**Web:** maintenance only unless required for API/backend.

## Module status

| # | Module | Status |
|---|--------|--------|
| 1 | Splash Screen | ✅ Done |
| 2 | Onboarding | ✅ Done |
| 3 | Login | ✅ API wired — i18n polish ongoing |
| 4 | Register | ✅ API wired — i18n polish ongoing |
| 5 | OTP Verification | ✅ Done (incl. password-reset flow) |
| 6 | Forgot Password | ✅ Done + reset password screen |
| 7 | Dashboard | ✅ API wired — UI polish ongoing |
| 8 | Wallet | ✅ Complete |
| 9 | Send Money | ✅ Complete |
| 10 | Beneficiaries | ✅ Complete |
| 11 | Transactions | ✅ Complete |
| 12 | KYC | ✅ API wired — i18n polish ongoing |
| 13 | Notifications | ✅ API wired — i18n polish ongoing |
| 14 | Profile | ✅ Complete |
| 15 | Settings | ✅ Complete |
| 16 | Security | ✅ Devices + password entry point |
| 17 | Admin mobile | ⏸ Not started (web admin sufficient for now) |

## CI builds (no local Android Studio required)

| Workflow | Trigger | Artifact |
|----------|---------|----------|
| **Mobile Debug APK** | Push to `main` (mobile-app changes) | `XMONEY-Debug-APK` |
| **Mobile Release APK** | Manual | `XMONEY-Release-APK` |
| **Mobile Release AAB** | Manual | `XMONEY-Release-AAB` |

Download APK: GitHub → **Actions** → latest **Mobile Debug APK** run → **Artifacts**.

## Project location

```
C:\XMONEY\mobile-app
```

## Next polish passes

- Full i18n on Login, Register, Home, KYC, Notifications
- Premium dashboard exchange board (parity with web coversheet)
- Real branding PNGs (`scripts/sync-branding-to-mobile.ps1`)
- Widget/integration tests
- Push notifications (FCM) when business approves

## Requirements checklist

- [x] Enterprise Material 3 theme (light / dark / system)
- [x] English, Arabic, Urdu + RTL/LTR
- [x] Responsive padding / breakpoints
- [x] Accessibility text scaling clamp
- [x] GitHub Actions debug APK
- [ ] Play Store / App Store release (later)
