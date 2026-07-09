<#
.SYNOPSIS
  Build an isolated cPanel upload package for XMONEY only.

.DESCRIPTION
  Creates deploy/cpanel/dist/xmoney-cpanel-package/ containing ONLY XMONEY files.
  Upload that folder's CONTENTS into public_html/xmoney/ on the server.
  This script never touches any existing project files on the server.

.EXAMPLE
  .\Build-CpanelPackage.ps1
#>

$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$Out = Join-Path $PSScriptRoot 'dist\xmoney-cpanel-package'

Write-Host "XMONEY root: $Root"
Write-Host "Output:      $Out"

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
Copy-Item (Join-Path $Root 'config\runtime-config.example.js') (Join-Path $Out 'config\runtime-config.example.js') -Force
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

# README inside package
@"
XMONEY cPanel Package
=====================
Upload the CONTENTS of this folder to: public_html/xmoney/

DO NOT upload into or overwrite any other public_html folder.

Next steps:
1. Create MySQL database + user for XMONEY only (see database/)
2. Import database/*.sql into the XMONEY database only
3. Copy api/.env.example -> api/.env and fill XMONEY credentials
4. Copy config/runtime-config.example.js -> config/runtime-config.js and set apiBaseUrl
5. On server: cd api && composer install --no-dev && php scripts/seed-admin.php
6. Visit /xmoney/ and /xmoney/admin/ and /xmoney/api/v1/health

Isolation policy: documentation/ISOLATION.md
"@ | Set-Content (Join-Path $Out 'DEPLOY_README.txt') -Encoding UTF8

# Zip
$zip = Join-Path $PSScriptRoot 'dist\xmoney-cpanel-package.zip'
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $Out '*') -DestinationPath $zip -Force

Write-Host ""
Write-Host "Package ready:"
Write-Host "  Folder: $Out"
Write-Host "  Zip:    $zip"
Write-Host "Upload ONLY into public_html/xmoney/"
