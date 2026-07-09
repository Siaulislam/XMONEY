# Inject official XMONEY branding into all HTML pages
$ErrorActionPreference = 'Stop'
$root = "$PSScriptRoot\.."

& "$PSScriptRoot\sync-branding-to-apps.ps1"

$logoNav = '<img src="src/assets/branding/xmoney-logo-nav.png" alt="XMONEY" width="148" height="40" class="xm-logo-img" />'
$logoNavAdmin = '<img src="src/assets/branding/xmoney-logo-nav.png" alt="XMONEY" width="132" height="36" class="xm-logo-img" /><span class="xm-logo-admin-tag">Admin</span>'
$logoHero = '<img src="src/assets/branding/xmoney-logo-nav.png" alt="XMONEY" class="xm-logo-hero-img" />'
$logoCard = '<img src="src/assets/branding/xmoney-logo-nav.png" alt="XMONEY" class="xm-logo-card-img" width="140" height="38" />'

$headSnippet = @'
  <link rel="icon" href="favicon.ico" sizes="any" />
  <link rel="icon" type="image/png" sizes="32x32" href="src/assets/branding/favicon-32x32.png" />
  <link rel="icon" type="image/png" sizes="16x16" href="src/assets/branding/favicon-16x16.png" />
  <link rel="apple-touch-icon" href="src/assets/branding/apple-touch-icon.png" />
  <link rel="manifest" href="manifest.webmanifest" />
  <meta name="theme-color" content="#000000" />
  <meta property="og:image" content="src/assets/branding/og-image.png" />
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:image" content="src/assets/branding/social-sharing.png" />
'@

function Update-Html([string]$Path, [bool]$IsAdmin) {
    if (-not (Test-Path $Path)) { return }
    $html = [System.IO.File]::ReadAllText($Path)
    $orig = $html

    if ($html -notmatch 'favicon\.ico') {
        $html = $html -replace '(<meta name="viewport"[^>]*>)', "`$1`n$headSnippet"
    }

    if ($IsAdmin) {
        $html = $html -replace '<a href="index\.html" class="xm-logo"><span class="xm-logo-mark">X</span> XMONEY Admin</a>', "<a href=`"index.html`" class=`"xm-logo xm-logo--admin`">$logoNavAdmin</a>"
        $html = $html -replace '<div class="xm-logo" style="color:var\(--xm-navy\);margin-bottom:1rem"><span class="xm-logo-mark">X</span> XMONEY Admin</div>', "<div class=`"xm-logo xm-logo--card`">$logoCard<span class=`"xm-logo-admin-tag`">Admin</span></div>"
    } else {
        $html = $html -replace '<a href="index\.html" class="xm-logo"><span class="xm-logo-mark">X</span> XMONEY</a>', "<a href=`"index.html`" class=`"xm-logo`">$logoNav</a>"
        $html = $html -replace '<div class="xm-logo" style="margin-bottom:1\.5rem;font-size:1\.1rem;opacity:0\.9">\s*<span class="xm-logo-mark">X</span> XMONEY\s*</div>', "<div class=`"xm-logo xm-logo--hero`">$logoHero</div>"
        $html = $html -replace '<div class="xm-logo" style="color:var\(--xm-navy\);font-size:1\.1rem;margin-bottom:0\.5rem"><span class="xm-logo-mark">X</span> XMONEY</div>', "<div class=`"xm-logo xm-logo--card`">$logoCard</div>"
    }

    if ($html -ne $orig) {
        [System.IO.File]::WriteAllText($Path, $html, [System.Text.UTF8Encoding]::new($false))
        Write-Host "Updated $Path"
    }
}

Get-ChildItem (Join-Path $root 'frontend-web\*.html') | ForEach-Object { Update-Html $_.FullName $false }
Get-ChildItem (Join-Path $root 'admin-panel\*.html') | ForEach-Object { Update-Html $_.FullName $true }

# shell.js customer
$shell = Join-Path $root 'frontend-web\src\assets\js\shell.js'
$s = [System.IO.File]::ReadAllText($shell)
$s = $s -replace '<div class="xm-sidebar-brand"><span class="xm-logo-mark">X</span> XMONEY</div>', '<div class="xm-sidebar-brand"><img src="src/assets/branding/xmoney-logo-nav.png" alt="XMONEY" class="xm-logo-img xm-logo-img--sidebar" width="132" height="36" /></div>'
[System.IO.File]::WriteAllText($shell, $s, [System.Text.UTF8Encoding]::new($false))
Write-Host 'Updated frontend shell.js'

Copy-Item (Join-Path $root 'frontend-web\src\assets\js\brand-head.js') (Join-Path $root 'admin-panel\src\assets\js\brand-head.js') -Force
Copy-Item (Join-Path $root 'frontend-web\src\assets\js\app-loader.js') (Join-Path $root 'admin-panel\src\assets\js\app-loader.js') -Force
Write-Host 'Branding injection complete.'
