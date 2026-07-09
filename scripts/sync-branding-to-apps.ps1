# Copy canonical web branding assets into frontend-web and admin-panel
$root = "$PSScriptRoot\.."
$webSrc = Join-Path $root 'assets\web'
$targets = @(
    (Join-Path $root 'frontend-web\src\assets\branding'),
    (Join-Path $root 'admin-panel\src\assets\branding')
)
$files = @(
    'favicon.ico', 'favicon-16x16.png', 'favicon-32x32.png', 'apple-touch-icon.png',
    'android-chrome-192x192.png', 'android-chrome-512x512.png',
    'pwa-192x192.png', 'pwa-512x512.png', 'og-image.png', 'social-sharing.png'
)
foreach ($t in $targets) {
    New-Item -ItemType Directory -Path $t -Force | Out-Null
    foreach ($f in $files) {
        Copy-Item (Join-Path $webSrc $f) (Join-Path $t $f) -Force
    }
    Copy-Item (Join-Path $root 'assets\branding\xmoney-logo.svg') (Join-Path $t 'xmoney-logo.svg') -Force
    Copy-Item (Join-Path $root 'assets\logos\xmoney-logo-full.png') (Join-Path $t 'xmoney-logo-nav.png') -Force
    Copy-Item (Join-Path $root 'assets\logos\xmoney-logo-monogram.png') (Join-Path $t 'xmoney-monogram.png') -Force
}
Copy-Item (Join-Path $webSrc 'favicon.ico') (Join-Path $root 'frontend-web\favicon.ico') -Force
Copy-Item (Join-Path $webSrc 'favicon.ico') (Join-Path $root 'admin-panel\favicon.ico') -Force
Write-Host 'Branding synced to frontend-web and admin-panel.'
