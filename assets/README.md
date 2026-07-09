# XMONEY Brand Assets

Official XMONEY branding generated from `logos/xmoney-logo-master.png`.

## Palette

| Token | Hex |
|-------|-----|
| Background | `#000000` |
| Gold | `#FFC107` |
| White | `#FFFFFF` |

## Structure

```
assets/
  logos/          Master PNG, full wordmark, monogram crops
  icons/          General-purpose PNG sizes
  android/        Launcher + adaptive icon layers
  ios/            AppIcon.appiconset + flat exports
  web/            Favicons, PWA, OG, social images
  splash/         Android, iOS, and web splash screens
  branding/       SVG, PDF, palette JSON
```

## Regenerate

```powershell
powershell -ExecutionPolicy Bypass -File scripts/generate-brand-assets.ps1
powershell -ExecutionPolicy Bypass -File scripts/inject-branding.ps1
powershell -ExecutionPolicy Bypass -File scripts/sync-branding-to-mobile.ps1
```

## Mobile native icons

After `flutter create .` in `mobile-app/`:

- **Android:** copy `assets/android/*` into `android/app/src/main/res/` using standard mipmap folders, and `assets/android/adaptive/*` for adaptive layers.
- **iOS:** copy `assets/ios/AppIcon.appiconset` into `ios/Runner/Assets.xcassets/AppIcon.appiconset`.
