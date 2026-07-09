<#
.SYNOPSIS
  Ensure web/admin branding PNGs and favicons exist before cPanel packaging.

.DESCRIPTION
  Generates minimal XMONEY-branded PNG assets when the full logo pipeline
  (assets/logos/xmoney-logo-master.png) has not been run yet.
#>
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$master = Join-Path $root 'assets\logos\xmoney-logo-master.png'
$generate = Join-Path $PSScriptRoot 'generate-brand-assets.ps1'
$sync = Join-Path $PSScriptRoot 'sync-branding-to-apps.ps1'

if ((Test-Path $master) -and (Test-Path $generate)) {
  & $generate
  if (Test-Path $sync) { & $sync }
  Write-Host 'Branding generated from master logo.'
  return
}

Add-Type -AssemblyName System.Drawing

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
  }
}

function Save-Png([System.Drawing.Bitmap]$Bmp, [string]$Path) {
  Ensure-Dir (Split-Path $Path -Parent)
  $Bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $Bmp.Dispose()
}

function New-BrandedBitmap([int]$Width, [int]$Height, [string]$Text) {
  $bmp = New-Object System.Drawing.Bitmap $Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.Clear([System.Drawing.Color]::Black)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $fontSize = [Math]::Max(10, [int][Math]::Round([Math]::Min($Width, $Height) * 0.22))
  $font = New-Object System.Drawing.Font 'Segoe UI', $fontSize, [System.Drawing.FontStyle]::Bold
  $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 193, 7))
  $size = $g.MeasureString($Text, $font)
  $x = [Math]::Max(0, ($Width - $size.Width) / 2)
  $y = [Math]::Max(0, ($Height - $size.Height) / 2)
  $g.DrawString($Text, $font, $brush, $x, $y)
  $g.Dispose()
  $font.Dispose()
  $brush.Dispose()
  return $bmp
}

function Save-Ico([string[]]$PngPaths, [string]$OutPath) {
  $images = @()
  foreach ($p in $PngPaths) {
    $images += [System.Drawing.Image]::FromFile($p)
  }
  $ms = New-Object System.IO.MemoryStream
  $bw = New-Object System.IO.BinaryWriter $ms
  $bw.Write([uint16]0)
  $bw.Write([uint16]1)
  $bw.Write([uint16]$images.Count)
  $offset = 6 + (16 * $images.Count)
  foreach ($img in $images) {
    $pngMs = New-Object System.IO.MemoryStream
    $img.Save($pngMs, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytes = $pngMs.ToArray()
    $pngMs.Dispose()
    $bw.Write([byte]$img.Width)
    $bw.Write([byte]$img.Height)
    $bw.Write([byte]0)
    $bw.Write([byte]0)
    $bw.Write([uint16]1)
    $bw.Write([uint16]32)
    $bw.Write([uint32]$pngBytes.Length)
    $bw.Write([uint32]$offset)
    $offset += $pngBytes.Length
  }
  foreach ($img in $images) {
    $pngMs = New-Object System.IO.MemoryStream
    $img.Save($pngMs, [System.Drawing.Imaging.ImageFormat]::Png)
    $bw.Write($pngMs.ToArray())
    $pngMs.Dispose()
    $img.Dispose()
  }
  Ensure-Dir (Split-Path $OutPath -Parent)
  [System.IO.File]::WriteAllBytes($OutPath, $ms.ToArray())
  $bw.Dispose()
  $ms.Dispose()
}

$targets = @(
  (Join-Path $root 'frontend-web\src\assets\branding'),
  (Join-Path $root 'admin-panel\src\assets\branding')
)

$files = @{
  'favicon-16x16.png' = { param($d) Save-Png (New-BrandedBitmap 16 16 'XM') (Join-Path $d 'favicon-16x16.png') }
  'favicon-32x32.png' = { param($d) Save-Png (New-BrandedBitmap 32 32 'XM') (Join-Path $d 'favicon-32x32.png') }
  'apple-touch-icon.png' = { param($d) Save-Png (New-BrandedBitmap 180 180 'XMONEY') (Join-Path $d 'apple-touch-icon.png') }
  'pwa-192x192.png' = { param($d) Save-Png (New-BrandedBitmap 192 192 'XMONEY') (Join-Path $d 'pwa-192x192.png') }
  'pwa-512x512.png' = { param($d) Save-Png (New-BrandedBitmap 512 512 'XMONEY') (Join-Path $d 'pwa-512x512.png') }
  'android-chrome-192x192.png' = { param($d) Save-Png (New-BrandedBitmap 192 192 'XMONEY') (Join-Path $d 'android-chrome-192x192.png') }
  'android-chrome-512x512.png' = { param($d) Save-Png (New-BrandedBitmap 512 512 'XMONEY') (Join-Path $d 'android-chrome-512x512.png') }
  'og-image.png' = { param($d) Save-Png (New-BrandedBitmap 1200 630 'XMONEY') (Join-Path $d 'og-image.png') }
  'social-sharing.png' = { param($d) Save-Png (New-BrandedBitmap 1200 630 'XMONEY') (Join-Path $d 'social-sharing.png') }
  'xmoney-logo-nav.png' = { param($d) Save-Png (New-BrandedBitmap 320 80 'XMONEY') (Join-Path $d 'xmoney-logo-nav.png') }
  'xmoney-monogram.png' = { param($d) Save-Png (New-BrandedBitmap 128 128 'XM') (Join-Path $d 'xmoney-monogram.png') }
}

foreach ($target in $targets) {
  Ensure-Dir $target
  foreach ($entry in $files.GetEnumerator()) {
    $path = Join-Path $target $entry.Key
    if (-not (Test-Path $path)) {
      & $entry.Value $target
    }
  }
  $svg = Join-Path $root 'assets\branding\xmoney-logo.svg'
  if (Test-Path $svg) {
    Copy-Item $svg (Join-Path $target 'xmoney-logo.svg') -Force
  }
}

$webBranding = Join-Path $root 'frontend-web\src\assets\branding'
$adminBranding = Join-Path $root 'admin-panel\src\assets\branding'
$f16 = Join-Path $webBranding 'favicon-16x16.png'
$f32 = Join-Path $webBranding 'favicon-32x32.png'
Save-Ico @($f16, $f32) (Join-Path $root 'frontend-web\favicon.ico')
Copy-Item (Join-Path $root 'frontend-web\favicon.ico') (Join-Path $root 'admin-panel\favicon.ico') -Force

Write-Host 'Deploy branding assets are ready for frontend-web and admin-panel.'
