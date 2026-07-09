<# 
.SYNOPSIS
  Quick hard-coded string audit for XMONEY web/admin/mobile surfaces.

.EXAMPLE
  .\scripts\audit-i18n.ps1
#>
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')

Write-Host "XMONEY i18n audit"
Write-Host ""

$checks = @(
  @{
    Name = 'Frontend HTML';
    Path = Join-Path $root 'frontend-web';
    Pattern = '">[A-Za-z][^<]*<|textContent = ''|showAlert\(|toast\(|placeholder=\"[A-Za-z]';
    Glob = '*.html'
  },
  @{
    Name = 'Admin HTML';
    Path = Join-Path $root 'admin-panel';
    Pattern = '">[A-Za-z][^<]*<|textContent = ''|showAlert\(|toast\(|placeholder=\"[A-Za-z]';
    Glob = '*.html'
  },
  @{
    Name = 'Mobile Dart';
    Path = Join-Path $root 'mobile-app\lib';
    Pattern = 'Text\(''([^'']*[A-Za-z][^'']*)''|labelText: ''([^'']*[A-Za-z][^'']*)''|showXmSnack\(context, ''';
    Glob = '*.dart'
  }
)

foreach ($check in $checks) {
  Write-Host "## $($check.Name)"
  & rg --glob $check.Glob --count-matches --sort path --pcre2 $check.Pattern $check.Path 2>$null
  Write-Host ""
}

Write-Host "Review high-count files first, then replace literals with shared i18n keys."
