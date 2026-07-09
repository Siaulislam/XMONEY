<#
.SYNOPSIS
  Bootstrap Flutter native projects for mobile-app (run once per machine).

.EXAMPLE
  .\scripts\bootstrap-mobile.ps1
#>
$ErrorActionPreference = 'Stop'
$mobile = Join-Path $PSScriptRoot '..\mobile-app' | Resolve-Path

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
  Write-Host 'Flutter SDK not found on PATH.'
  Write-Host 'Install from https://docs.flutter.dev/get-started/install then re-run this script.'
  exit 1
}

Push-Location $mobile
try {
  if (-not (Test-Path 'android')) {
    Write-Host 'Creating android/ and ios/ via flutter create...'
    flutter create . --org ae.tasjeel.xmoney --project-name xmoney
  } else {
    Write-Host 'Native folders exist — running flutter pub get only.'
  }
  flutter pub get
  & (Join-Path $PSScriptRoot 'sync-branding-to-mobile.ps1')
  Write-Host ''
  Write-Host 'Mobile bootstrap complete. Run: cd mobile-app && flutter run'
  Write-Host 'See mobile-app/MOBILE_SETUP.md for details.'
} finally {
  Pop-Location
}
