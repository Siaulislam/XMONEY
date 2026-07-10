#!/usr/bin/env bash
# Prepare mobile-app for CI: branding placeholders, native platforms, pub get.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BRAND="$ROOT/assets/branding"
mkdir -p "$BRAND"

gen_png() {
  local out="$1"
  local w="$2"
  local h="$3"
  local label="$4"
  if [[ -f "$out" ]]; then
    return 0
  fi
  if command -v convert >/dev/null 2>&1; then
    convert -size "${w}x${h}" xc:'#000000' \
      -fill '#FFC107' -gravity center -pointsize 42 -annotate 0 "$label" \
      "$out"
  else
    # 1x1 black PNG fallback (Flutter asset load — replace with real branding later)
    printf '\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xdb\x00\x00\x00\x00IEND\xaeB`\x82' > "$out"
  fi
}

gen_png "$BRAND/xmoney-logo.png" 320 96 'XMONEY'
gen_png "$BRAND/xmoney-logo-full.png" 560 160 'XMONEY'
gen_png "$BRAND/xmoney-monogram.png" 128 128 'XM'
gen_png "$BRAND/splash-android.png" 1080 1920 'XMONEY'
gen_png "$BRAND/splash-ios.png" 1290 2796 'XMONEY'
gen_png "$BRAND/app-icon-1024.png" 1024 1024 'XM'

if [[ ! -f android/app/build.gradle ]]; then
  echo "Generating Android/iOS platform folders…"
  flutter create . --org com.smartdms.xmoney --project-name xmoney_app --platforms=android,ios
fi

flutter pub get
flutter analyze --no-fatal-infos
