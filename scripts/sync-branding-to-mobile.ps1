# Copies canonical branding assets into the Flutter mobile-app package.
$root = "$PSScriptRoot\.."
$dest = Join-Path $root 'mobile-app\assets\branding'
New-Item -ItemType Directory -Path $dest -Force | Out-Null
$map = @{
    'logos/xmoney-logo-master.png' = 'xmoney-logo.png'
    'logos/xmoney-logo-full.png' = 'xmoney-logo-full.png'
    'logos/xmoney-logo-monogram.png' = 'xmoney-monogram.png'
    'splash/android/splash-portrait-1080x1920.png' = 'splash-android.png'
    'splash/ios/splash-1290x2796.png' = 'splash-ios.png'
    'ios/icon-1024.png' = 'app-icon-1024.png'
}
foreach ($entry in $map.GetEnumerator()) {
    Copy-Item (Join-Path $root "assets\$($entry.Key)") (Join-Path $dest $entry.Value) -Force
}
Write-Host 'Mobile branding assets synced.'
