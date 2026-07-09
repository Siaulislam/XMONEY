<#
.SYNOPSIS
  Local repository validation (no deploy, no secrets).

.EXAMPLE
  .\scripts\validate-repo.ps1
  .\scripts\validate-repo.ps1 -CheckApi
#>
param(
  [switch]$CheckApi,
  [string]$ApiBase = 'https://qamar.tasjeel.ae/xmoney/api'
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')

Write-Host "XMONEY validate-repo"
Write-Host "Root: $root"
Write-Host ""

# Required paths
$required = @(
  'backend-api/src/routes/api.php',
  'backend-api/scripts/smoke-test.php',
  'backend-api/scripts/e2e-flow-test.php',
  'database/migrations/003_wallet_payments_analytics.sql',
  'frontend-web/config/runtime-config.js',
  'admin-panel/config/runtime-config.js',
  'mobile-app/pubspec.yaml',
  'deploy/cpanel/Build-CpanelPackage.ps1'
)
foreach ($rel in $required) {
  $p = Join-Path $root $rel
  if (-not (Test-Path $p)) { throw "Missing required file: $rel" }
  Write-Host "[OK] $rel"
}

# Build cPanel package structure
Write-Host ""
Write-Host "Building cPanel package..."
& (Join-Path $root 'deploy\cpanel\Build-CpanelPackage.ps1') | Out-Null
$pkg = Join-Path $root 'deploy\cpanel\dist\xmoney-cpanel-package'
@('api\public\index.php', 'index.html', 'admin\index.html', 'database\02_schema_no_create_db.sql') | ForEach-Object {
  if (-not (Test-Path (Join-Path $pkg $_))) { throw "Package missing: $_" }
  Write-Host "[OK] package/$_"
}

if ($CheckApi) {
  Write-Host ""
  & (Join-Path $PSScriptRoot 'verify-e2e-readiness.ps1') -ApiBase $ApiBase
}

Write-Host ""
Write-Host 'Repository validation passed.'
