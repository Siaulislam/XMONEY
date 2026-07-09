# Sync shared enterprise UI assets to frontend-web and admin-panel
$root = "$PSScriptRoot\.."
$shared = Join-Path $root 'shared\ui'
$targets = @(
    (Join-Path $root 'frontend-web\src\assets'),
    (Join-Path $root 'admin-panel\src\assets')
)

$css = Get-ChildItem (Join-Path $shared 'css') -Filter '*.css'
$js = Get-ChildItem (Join-Path $shared 'js') -Filter '*.js'
$i18n = Get-ChildItem (Join-Path $shared 'i18n') -Filter '*.json'

foreach ($t in $targets) {
    New-Item -ItemType Directory -Path (Join-Path $t 'css') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $t 'js') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $t 'i18n') -Force | Out-Null
    foreach ($f in $css) { Copy-Item $f.FullName (Join-Path $t "css\$($f.Name)") -Force }
    foreach ($f in $js) { Copy-Item $f.FullName (Join-Path $t "js\$($f.Name)") -Force }
    foreach ($f in $i18n) { Copy-Item $f.FullName (Join-Path $t "i18n\$($f.Name)") -Force }
}
Write-Host 'Enterprise UI assets synced to frontend-web and admin-panel.'
