<#
.SYNOPSIS
  Build an isolated cPanel upload package for XMONEY only.

.DESCRIPTION
  Creates deploy/cpanel/dist/xmoney-cpanel-package/ containing ONLY XMONEY files.
  Upload that folder's CONTENTS into public_html/ on the server.
  This script never touches files outside the XMONEY deployment set.

.EXAMPLE
  .\Build-CpanelPackage.ps1
#>

$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$Out = Join-Path $PSScriptRoot 'dist\xmoney-cpanel-package'
$EnsureBranding = Join-Path $Root 'scripts\ensure-deploy-branding.ps1'

Write-Host "XMONEY root: $Root"
Write-Host "Output:      $Out"

if (Test-Path $EnsureBranding) {
  Write-Host "Ensuring branding assets..."
  & $EnsureBranding
}

if (Test-Path $Out) {
  Remove-Item $Out -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $Out | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Out 'admin') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Out 'api') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Out 'config') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Out 'storage\uploads\kyc') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Out 'storage\uploads\profiles') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Out 'storage\uploads\temp') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Out 'storage\logs') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Out 'storage\backups') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Out 'database') | Out-Null

function Copy-DirectoryFiltered {
  param(
    [Parameter(Mandatory = $true)][string]$Source,
    [Parameter(Mandatory = $true)][string]$Destination,
    [string[]]$ExcludeNames = @()
  )

  New-Item -ItemType Directory -Force -Path $Destination | Out-Null

  Get-ChildItem -LiteralPath $Source -Force | ForEach-Object {
    if ($ExcludeNames -contains $_.Name) { return }

    $target = Join-Path $Destination $_.Name
    if ($_.PSIsContainer) {
      Copy-DirectoryFiltered -Source $_.FullName -Destination $target -ExcludeNames $ExcludeNames
    } else {
      Copy-Item $_.FullName $target -Force
    }
  }
}

# Root htaccess
Copy-Item (Join-Path $PSScriptRoot 'package-template\.htaccess') (Join-Path $Out '.htaccess') -Force

# Customer web → package root (app)
$webSrc = Join-Path $Root 'frontend-web'
Copy-Item (Join-Path $webSrc '*') $Out -Recurse -Force -Exclude @('.git')

# Admin panel → /admin
Copy-Item (Join-Path $Root 'admin-panel\*') (Join-Path $Out 'admin') -Recurse -Force

# Backend API → /api (full source; vendor installed later in workflow/server)
$apiSrc = Join-Path $Root 'backend-api'
Copy-DirectoryFiltered -Source $apiSrc -Destination (Join-Path $Out 'api') -ExcludeNames @('vendor', '.git')

# Prefer production env example inside package
Copy-Item (Join-Path $Root 'config\env.production.example') (Join-Path $Out 'api\.env.example') -Force

# Override api public htaccess for cPanel
Copy-Item (Join-Path $PSScriptRoot 'package-template\api-public.htaccess') (Join-Path $Out 'api\public\.htaccess') -Force

# Protect storage
Copy-Item (Join-Path $PSScriptRoot 'package-template\storage.htaccess') (Join-Path $Out 'storage\.htaccess') -Force
'' | Set-Content (Join-Path $Out 'storage\uploads\kyc\.gitkeep')
'' | Set-Content (Join-Path $Out 'storage\logs\.gitkeep')
'' | Set-Content (Join-Path $Out 'storage\backups\.gitkeep')

# Public runtime config (no secrets)
$runtimeExample = Join-Path $Root 'config\runtime-config.example.js'
$runtimeLive = Join-Path $Root 'frontend-web\config\runtime-config.js'
Copy-Item $runtimeExample (Join-Path $Out 'config\runtime-config.example.js') -Force
if (Test-Path $runtimeLive) {
  Copy-Item $runtimeLive (Join-Path $Out 'config\runtime-config.js') -Force
} else {
  Copy-Item $runtimeExample (Join-Path $Out 'config\runtime-config.js') -Force
}
Copy-Item (Join-Path $PSScriptRoot 'package-template\config.htaccess') (Join-Path $Out 'config\.htaccess') -Force

# Database import pack (XMONEY DB only)
Copy-Item (Join-Path $Root 'database\cpanel\*') (Join-Path $Out 'database') -Recurse -Force
Copy-Item (Join-Path $Root 'database\migrations\*') (Join-Path $Out 'database\migrations') -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $Out 'database\migrations') | Out-Null
Copy-Item (Join-Path $Root 'database\migrations\*') (Join-Path $Out 'database\migrations') -Force

# Inject runtime-config script into HTML pages (customer + admin) if missing
function Add-RuntimeConfigScript([string]$HtmlPath, [string]$RelativeConfig) {
  $content = Get-Content $HtmlPath -Raw -ErrorAction SilentlyContinue
  if (-not $content) { return }
  if ($content -match 'runtime-config\.js') { return }
  $tag = "<script src=`"$RelativeConfig`"></script>`r`n"
  if ($content -match '(?i)</head>') {
    $content = $content -replace '(?i)</head>', ($tag + '</head>')
    Set-Content -Path $HtmlPath -Value $content -Encoding UTF8
  }
}

Get-ChildItem $Out -Filter '*.html' -File | ForEach-Object {
  Add-RuntimeConfigScript $_.FullName 'config/runtime-config.js'
}
Get-ChildItem (Join-Path $Out 'admin') -Filter '*.html' -File | ForEach-Object {
  Add-RuntimeConfigScript $_.FullName '../config/runtime-config.js'
}

# Verify required live files are present in the package
$required = @(
  'index.html',
  '.htaccess',
  'favicon.ico',
  'config\runtime-config.js',
  'src\assets\css\xmoney.css',
  'src\assets\branding\xmoney-logo-nav.png',
  'admin\index.html',
  'admin\config\runtime-config.js',
  'api\public\index.php',
  'api\.env.example',
  'storage\uploads\kyc',
  'database\02_schema_no_create_db.sql'
)
foreach ($rel in $required) {
  $path = Join-Path $Out $rel
  if (-not (Test-Path $path)) {
    throw "Package incomplete: missing $rel"
  }
}

# README inside package
@"
XMONEY cPanel Package — FULL SERVER UPLOAD
==========================================
Upload the CONTENTS of this folder to:
  /home/smartdms/public_html/

Do NOT upload the repository source tree (frontend-web, admin-panel, backend-api folders).

This package already includes:
- index.html and all customer pages
- admin/ panel
- api/ backend source
- config/runtime-config.js
- src/assets CSS, JS, branding images
- storage/, database SQL pack, .htaccess

After upload:
1. Copy api/.env.example -> api/.env and fill DB + JWT + SMTP values
2. Ensure api/vendor/ exists (included if you used GitHub "Build cPanel Package" workflow)
3. If api/vendor/ is missing and Composer is not on the server, download the zip from GitHub Actions artifact instead
4. Optional: php scripts/seed-admin.php "YourStrongPassword"
5. Test:
   - https://smartdms.me/
   - https://smartdms.me/admin/
   - https://smartdms.me/api/v1/health
"@ | Set-Content (Join-Path $Out 'UPLOAD_TO_PUBLIC_HTML.txt') -Encoding UTF8

@"
XMONEY SERVER CHECKLIST (verify in cPanel after upload)
=======================================================

Your folder structure is CORRECT if public_html contains:
  admin/   api/   config/   database/   src/   storage/   index.html   .htaccess

CRITICAL FILES — open each path in File Manager:

[ ] public_html/src/assets/css/xmoney.css
[ ] public_html/src/assets/css/tokens.css
[ ] public_html/src/assets/branding/xmoney-logo-nav.png
[ ] public_html/config/runtime-config.js
[ ] public_html/api/.env          (copy from api/.env.example)
[ ] public_html/api/vendor/       (created by composer install)
[ ] public_html/api/public/index.php

AFTER UPLOAD — if api/vendor/ is missing (Composer not on server):

  Use GitHub Actions -> "Build cPanel Package" -> download artifact zip
  That zip already includes api/vendor/.

If Composer IS available on the server:

  cd ~/public_html/api
  cp .env.example .env
  nano .env
  composer install --no-dev --optimize-autoloader

Fill .env with:
  DB_NAME=smartdms_XMONEY
  DB_USER=smartdms_xmoney
  DB_PASS=your_password
  JWT_SECRET=long_random_secret_min_32_chars
  APP_URL=https://smartdms.me/api
  MAIL_DRIVER=smtp
  SMTP_HOST=mail.smartdms.me
  SMTP_PORT=465
  SMTP_SECURE=ssl
  SMTP_USER=xmoney@smartdms.me
  SMTP_PASS=your_mailbox_password
  MAIL_FROM_ADDRESS=xmoney@smartdms.me
  MAIL_FROM_NAME=XMONEY

TEST URLS:
  https://smartdms.me/src/assets/css/xmoney.css   -> must show CSS (not 404)
  https://smartdms.me/config/runtime-config.js    -> must show JS config
  https://smartdms.me/api/v1/health               -> must return JSON (not 500)

WHY PAGE LOOKS UNSTYLED:
  xmoney.css is missing or css/ folder is empty -> re-upload full zip contents.

WHY API SHOWS 500:
  api/vendor/ missing OR api/.env missing -> run composer + create .env.
"@ | Set-Content (Join-Path $Out 'SERVER_CHECKLIST.txt') -Encoding UTF8

# Optional: bundle Composer vendor if composer is available locally
$composer = Get-Command composer -ErrorAction SilentlyContinue
if ($composer) {
  Write-Host 'Installing API dependencies into package (vendor/)...'
  Push-Location (Join-Path $Out 'api')
  composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist 2>&1 | Write-Host
  Pop-Location
  if (Test-Path (Join-Path $Out 'api\vendor\autoload.php')) {
    Write-Host 'API vendor/ included in package.'
  } else {
    Write-Host 'WARNING: vendor/ not created — run composer install on server after upload.'
  }
} else {
  Write-Host 'Composer not on PATH — run composer install on server after upload.'
}

# Zip
$zip = Join-Path $PSScriptRoot 'dist\xmoney-cpanel-package.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $Out '*') -DestinationPath $zip -Force

Write-Host ""
Write-Host "Package ready:"
Write-Host "  Folder: $Out"
Write-Host "  Zip:    $zip"
Write-Host "Upload ONLY into public_html/"
