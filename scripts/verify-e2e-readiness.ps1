<#
.SYNOPSIS
  Check whether the XMONEY API is reachable and print E2E readiness hints.

.EXAMPLE
  .\scripts\verify-e2e-readiness.ps1
  .\scripts\verify-e2e-readiness.ps1 -ApiBase https://smartdms.me/api
#>
param(
  [string]$ApiBase = 'https://smartdms.me/api'
)

$ErrorActionPreference = 'Continue'
$base = $ApiBase.TrimEnd('/')
$healthUrl = "$base/v1/health"

Write-Host "XMONEY E2E readiness check"
Write-Host "API: $base"
Write-Host ""

$ready = $true

try {
  $r = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 20
  Write-Host "[OK] Health HTTP $($r.StatusCode)"
  if ($r.Content -match 'success|healthy') {
    Write-Host "[OK] Health body looks valid"
  } else {
    Write-Host "[WARN] Unexpected health response body"
  }
} catch {
  Write-Host "[BLOCKED] Health endpoint unreachable: $($_.Exception.Message)"
  Write-Host "        Database may be ready but API files are not deployed yet."
  Write-Host "        See documentation/DEPLOY_WHEN_READY.md"
  $ready = $false
}

Write-Host ""
Write-Host "Next automated tests (requires PHP on PATH):"
Write-Host "  php backend-api/scripts/smoke-test.php $base"
Write-Host "  php backend-api/scripts/e2e-flow-test.php $base"
Write-Host ""
Write-Host "Manual checklist: documentation/E2E_TESTING.md"

if (-not $ready) { exit 2 }
exit 0
