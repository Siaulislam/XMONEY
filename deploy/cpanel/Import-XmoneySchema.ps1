<#
.SYNOPSIS
  Import XMONEY schema/seed into smartdms_XMONEY only (never SmartDMS DB).

.DESCRIPTION
  Requires mysql client and credentials via environment variables or parameters.
  Refuses to run if database name is not smartdms_XMONEY.

.EXAMPLE
  $env:XMONEY_DB_HOST='localhost'  # or remote host if allowed
  $env:XMONEY_DB_NAME='smartdms_XMONEY'
  $env:XMONEY_DB_USER='smartdms_xmoney'
  $env:XMONEY_DB_PASS='your-password'
  .\Import-XmoneySchema.ps1
#>

param(
  [string]$DbHost = $env:XMONEY_DB_HOST,
  [string]$DbName = $env:XMONEY_DB_NAME,
  [string]$DbUser = $env:XMONEY_DB_USER,
  [string]$DbPass = $env:XMONEY_DB_PASS,
  [int]$DbPort = 3306
)

$ErrorActionPreference = 'Stop'
$Root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$Schema = Join-Path $Root 'database\cpanel\02_schema_no_create_db.sql'
$Seed = Join-Path $Root 'database\cpanel\03_seed.sql'

if (-not $DbHost -or -not $DbName -or -not $DbUser -or -not $DbPass) {
  throw "Set XMONEY_DB_HOST, XMONEY_DB_NAME, XMONEY_DB_USER, XMONEY_DB_PASS (or pass -DbHost/-DbName/-DbUser/-DbPass)."
}

if ($DbName -ne 'smartdms_XMONEY') {
  throw "REFUSED: Database must be exactly 'smartdms_XMONEY'. Got '$DbName'."
}

if ($DbName -eq 'smartdms_smartdms_db') {
  throw "REFUSED: Will never import into SmartDMS database."
}

$mysql = Get-Command mysql -ErrorAction SilentlyContinue
if (-not $mysql) {
  throw "mysql client not found on PATH. Use phpMyAdmin import instead (see IMPORT_TO_PRODUCTION.md)."
}

Write-Host "Target host: $DbHost"
Write-Host "Target DB:   $DbName (XMONEY only)"
Write-Host "Importing schema..."
& mysql -h $DbHost -P $DbPort -u $DbUser "-p$DbPass" $DbName -e "SELECT DATABASE();" | Write-Host
Get-Content $Schema -Raw | & mysql -h $DbHost -P $DbPort -u $DbUser "-p$DbPass" $DbName
Write-Host "Importing seed..."
Get-Content $Seed -Raw | & mysql -h $DbHost -P $DbPort -u $DbUser "-p$DbPass" $DbName

Write-Host "Verifying tables..."
& mysql -h $DbHost -P $DbPort -u $DbUser "-p$DbPass" $DbName -e @"
SELECT DATABASE() AS current_database;
SELECT COUNT(*) AS table_count FROM information_schema.tables WHERE table_schema = DATABASE() AND table_type='BASE TABLE';
SHOW TABLES;
"@

Write-Host "Done. Confirm table_count is 23+ and current_database is smartdms_XMONEY."
