# Inject enterprise UI scripts into all HTML pages
$ErrorActionPreference = 'Stop'
& "$PSScriptRoot\sync-enterprise-ui.ps1"

$snippet = @'
  <script src="src/assets/js/xm-theme.js"></script>
  <script src="src/assets/js/xm-i18n.js"></script>
  <script src="src/assets/js/xm-responsive.js"></script>
  <script src="src/assets/js/xm-core.js"></script>
'@

function Update-Html([string]$Path) {
    if (-not (Test-Path $Path)) { return }
    $html = [System.IO.File]::ReadAllText($Path)
    if ($html -match 'xm-core\.js') { return }
    $html = $html -replace '(</head>)', "$snippet`n`$1"
    [System.IO.File]::WriteAllText($Path, $html, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Injected UI core: $Path"
}

Get-ChildItem "$PSScriptRoot\..\frontend-web\*.html" | ForEach-Object { Update-Html $_.FullName }
Get-ChildItem "$PSScriptRoot\..\admin-panel\*.html" | ForEach-Object { Update-Html $_.FullName }

# Sync xmoney.css imports to admin
Copy-Item "$PSScriptRoot\..\frontend-web\src\assets\css\xmoney.css" "$PSScriptRoot\..\admin-panel\src\assets\css\xmoney.css" -Force
Write-Host 'Enterprise UI injection complete.'
