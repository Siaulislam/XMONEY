# XMONEY official branding asset generator
# Source: assets/logos/xmoney-logo-master.png (1024x1024)
param(
    [string]$MasterPath = "$PSScriptRoot\..\assets\logos\xmoney-logo-master.png",
    [string]$Root = "$PSScriptRoot\..\assets"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$GOLD = [System.Drawing.Color]::FromArgb(255, 255, 193, 7)   # #FFC107
$BLACK = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
$WHITE = [System.Drawing.Color]::White

function Ensure-Dir([string]$Path) {
    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

function Get-ContentBounds([System.Drawing.Bitmap]$Bmp, [int]$Threshold = 25) {
    $w = $Bmp.Width; $h = $Bmp.Height
    $minX = $w; $minY = $h; $maxX = 0; $maxY = 0
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            $c = $Bmp.GetPixel($x, $y)
            if ($c.R -gt $Threshold -or $c.G -gt $Threshold -or $c.B -gt $Threshold) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }
  return @{ X = $minX; Y = $minY; W = ($maxX - $minX + 1); H = ($maxY - $minY + 1) }
}

function Copy-Region([System.Drawing.Bitmap]$Src, [int]$X, [int]$Y, [int]$W, [int]$H) {
    $dst = New-Object System.Drawing.Bitmap($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($dst)
    $g.DrawImage($Src, (New-Object System.Drawing.Rectangle 0, 0, $W, $H), $X, $Y, $W, $H, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    return $dst
}

function Set-BlackTransparent([System.Drawing.Bitmap]$Bmp, [int]$Threshold = 18) {
    for ($y = 0; $y -lt $Bmp.Height; $y++) {
        for ($x = 0; $x -lt $Bmp.Width; $x++) {
            $c = $Bmp.GetPixel($x, $y)
            if ($c.R -le $Threshold -and $c.G -le $Threshold -and $c.B -le $Threshold) {
                $Bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            }
        }
    }
}

function Resize-Bitmap([System.Drawing.Bitmap]$Src, [int]$Size, [bool]$Transparent = $false, [double]$Padding = 0.08) {
    $pad = [int][Math]::Round($Size * $Padding)
    $inner = $Size - (2 * $pad)
    $dst = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($dst)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $ratio = [Math]::Min($inner / $Src.Width, $inner / $Src.Height)
    $nw = [int][Math]::Round($Src.Width * $ratio)
    $nh = [int][Math]::Round($Src.Height * $ratio)
    $ox = [int][Math]::Round(($Size - $nw) / 2)
    $oy = [int][Math]::Round(($Size - $nh) / 2)
    $g.DrawImage($Src, $ox, $oy, $nw, $nh)
    $g.Dispose()
    if ($Transparent) { Set-BlackTransparent $dst }
    return $dst
}

function Save-Png([System.Drawing.Bitmap]$Bmp, [string]$Path) {
    Ensure-Dir (Split-Path $Path -Parent)
    $Bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Save-SolidPng([int]$Size, [System.Drawing.Color]$Color, [string]$Path) {
    $bmp = New-Object System.Drawing.Bitmap $Size, $Size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear($Color)
    $g.Dispose()
    Save-Png $bmp $Path
    $bmp.Dispose()
}

function Save-Splash([System.Drawing.Bitmap]$Logo, [int]$W, [int]$H, [string]$Path, [double]$LogoScale = 0.62) {
    $bmp = New-Object System.Drawing.Bitmap $W, $H
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear($BLACK)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $maxW = [int]($W * $LogoScale)
    $maxH = [int]($H * $LogoScale)
    $ratio = [Math]::Min($maxW / $Logo.Width, $maxH / $Logo.Height)
    $nw = [int][Math]::Round($Logo.Width * $ratio)
    $nh = [int][Math]::Round($Logo.Height * $ratio)
    $ox = [int][Math]::Round(($W - $nw) / 2)
    $oy = [int][Math]::Round(($H - $nh) / 2)
    $g.DrawImage($Logo, $ox, $oy, $nw, $nh)
    $g.Dispose()
    Save-Png $bmp $Path
    $bmp.Dispose()
}

function Save-OgImage([System.Drawing.Bitmap]$Logo, [string]$Path) {
    $W = 1200; $H = 630
    $bmp = New-Object System.Drawing.Bitmap $W, $H
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear($BLACK)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $maxW = [int]($W * 0.55); $maxH = [int]($H * 0.78)
    $ratio = [Math]::Min($maxW / $Logo.Width, $maxH / $Logo.Height)
    $nw = [int][Math]::Round($Logo.Width * $ratio)
    $nh = [int][Math]::Round($Logo.Height * $ratio)
    $ox = [int][Math]::Round(($W - $nw) / 2)
    $oy = [int][Math]::Round(($H - $nh) / 2)
    $g.DrawImage($Logo, $ox, $oy, $nw, $nh)
    $g.Dispose()
    Save-Png $bmp $Path
    $bmp.Dispose()
}

function Save-Ico([string[]]$PngPaths, [string]$OutPath) {
    $images = @()
    foreach ($p in $PngPaths) {
        $img = [System.Drawing.Image]::FromFile($p)
        $images += $img
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
    $bw.Dispose(); $ms.Dispose()
}

function Save-SvgEmbedded([string]$PngPath, [string]$OutPath, [string]$Title) {
    $bytes = [System.IO.File]::ReadAllBytes($PngPath)
    $b64 = [Convert]::ToBase64String($bytes)
    $svg = @"
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1024 1024" role="img" aria-label="$Title">
  <title>$Title</title>
  <image width="1024" height="1024" xlink:href="data:image/png;base64,$b64"/>
</svg>
"@
    Ensure-Dir (Split-Path $OutPath -Parent)
    [System.IO.File]::WriteAllText($OutPath, $svg, [System.Text.UTF8Encoding]::new($false))
}

function Save-PdfEmbedded([string]$PngPath, [string]$OutPath, [string]$Title) {
    $img = [System.Drawing.Image]::FromFile($PngPath)
    $w = $img.Width; $h = $img.Height
    $img.Dispose()
    $jpegMs = New-Object System.IO.MemoryStream
    $bmp = New-Object System.Drawing.Bitmap($PngPath)
    $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, 95L)
    $bmp.Save($jpegMs, $enc, $ep)
    $bmp.Dispose()
    $jpg = $jpegMs.ToArray()
    $jpegMs.Dispose()

    $header = "%PDF-1.4`n"
    $o1 = "1 0 obj`n<< /Type /Catalog /Pages 2 0 R >>`nendobj`n"
    $o2 = "2 0 obj`n<< /Type /Pages /Kids [3 0 R] /Count 1 >>`nendobj`n"
    $o3 = "3 0 obj`n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $w $h] /Resources << /XObject << /Im1 4 0 R >> >> /Contents 5 0 R >>`nendobj`n"
    $o4h = "4 0 obj`n<< /Type /XObject /Subtype /Image /Width $w /Height $h /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length $($jpg.Length) >>`nstream`n"
    $o4t = "`nendstream`nendobj`n"
    $o5 = "5 0 obj`n<< /Length 44 >>`nstream`nq $w 0 0 $h 0 0 cm /Im1 Do Q`nendstream`nendobj`n"

    $pos1 = [System.Text.Encoding]::ASCII.GetByteCount($header)
    $pos2 = [System.Text.Encoding]::ASCII.GetByteCount($header + $o1)
    $pos3 = [System.Text.Encoding]::ASCII.GetByteCount($header + $o1 + $o2)
    $pos4 = [System.Text.Encoding]::ASCII.GetByteCount($header + $o1 + $o2 + $o3)
    $pos5 = $pos4 + [System.Text.Encoding]::ASCII.GetByteCount($o4h) + $jpg.Length + [System.Text.Encoding]::ASCII.GetByteCount($o4t)

    $ms = New-Object System.IO.MemoryStream
    $sw = New-Object System.IO.StreamWriter($ms, [System.Text.Encoding]::ASCII)
    $sw.Write($header + $o1 + $o2 + $o3 + $o4h)
    $sw.Flush()
    $ms.Write($jpg, 0, $jpg.Length)
    $sw.Write($o4t + $o5)
    $sw.Flush()
    $xrefAt = $ms.Length
    $fmt = '{0:D10}'
    $xref = "xref`n0 6`n0000000000 65535 f `n$($fmt -f $pos1) 00000 n `n$($fmt -f $pos2) 00000 n `n$($fmt -f $pos3) 00000 n `n$($fmt -f $pos4) 00000 n `n$($fmt -f $pos5) 00000 n `n"
    $trailer = "trailer`n<< /Size 6 /Root 1 0 R >>`nstartxref`n$xrefAt`n%%EOF`n"
    $sw.Write($xref + $trailer)
    $sw.Flush()
    Ensure-Dir (Split-Path $OutPath -Parent)
    [System.IO.File]::WriteAllBytes($OutPath, $ms.ToArray())
    $sw.Dispose(); $ms.Dispose()
}

# --- Main ---
if (-not (Test-Path $MasterPath)) { throw "Master logo not found: $MasterPath" }

$dirs = @('logos','icons','android','ios','web','splash','branding','splash/android','splash/ios','splash/web','android/adaptive','ios/AppIcon.appiconset')
foreach ($d in $dirs) { Ensure-Dir (Join-Path $Root $d) }

$master = New-Object System.Drawing.Bitmap($MasterPath)
$bounds = Get-ContentBounds $master
$full = Copy-Region $master $bounds.X $bounds.Y $bounds.W $bounds.H
$monoH = [int][Math]::Round($bounds.H * 0.48)
$mono = Copy-Region $master $bounds.X $bounds.Y $bounds.W $monoH

# Master already at logos/xmoney-logo-master.png — do not overwrite while loaded
Save-Png $full (Join-Path $Root 'logos/xmoney-logo-full.png')
Save-Png $mono (Join-Path $Root 'logos/xmoney-logo-monogram.png')

# Branding palette
@(
    @{ Name = 'xmoney-palette.json'; Content = (@{ background = '#000000'; gold = '#FFC107'; white = '#FFFFFF' } | ConvertTo-Json) }
    @{ Name = 'BRAND.md'; Content = @"
# XMONEY Brand Assets

| Token | Value |
|-------|-------|
| Background | #000000 |
| Gold | #FFC107 |
| White | #FFFFFF |

Master logo: logos/xmoney-logo-master.png
"@ }
) | ForEach-Object {
    [System.IO.File]::WriteAllText((Join-Path $Root "branding/$($_.Name)"), $_.Content, [System.Text.UTF8Encoding]::new($false))
}

Save-SvgEmbedded (Join-Path $Root 'logos/xmoney-logo-master.png') (Join-Path $Root 'branding/xmoney-logo.svg') 'XMONEY'
Save-SvgEmbedded (Join-Path $Root 'logos/xmoney-logo-monogram.png') (Join-Path $Root 'branding/xmoney-monogram.svg') 'XMONEY Monogram'
Save-PdfEmbedded (Join-Path $Root 'logos/xmoney-logo-master.png') (Join-Path $Root 'branding/xmoney-logo-print.pdf') 'XMONEY Logo'

function Export-IconSet([System.Drawing.Bitmap]$Source, [string]$BaseDir, [string]$Prefix, [int[]]$Sizes, [bool]$Transparent) {
    foreach ($s in $Sizes) {
        $bmp = Resize-Bitmap $Source $s $Transparent
        $name = if ($Prefix) { "$Prefix-$s.png" } else { "icon-$s.png" }
        Save-Png $bmp (Join-Path $BaseDir $name)
        $bmp.Dispose()
    }
}

# Android launcher icons
$androidSizes = @(48, 72, 96, 144, 192, 512)
Export-IconSet $mono (Join-Path $Root 'android') 'ic_launcher' $androidSizes $false
Export-IconSet $mono (Join-Path $Root 'android') 'ic_launcher_round' $androidSizes $false

# Adaptive icon (432px standard)
Save-SolidPng 432 $BLACK (Join-Path $Root 'android/adaptive/ic_launcher_background.png')
$fg = Resize-Bitmap $mono 432 $true 0.12
Save-Png $fg (Join-Path $Root 'android/adaptive/ic_launcher_foreground.png')
$fg.Dispose()
$adaptive = Resize-Bitmap $mono 432 $false 0.12
Save-Png $adaptive (Join-Path $Root 'android/adaptive/ic_launcher.png')
$adaptive.Dispose()

# iOS AppIcon sizes
$iosSizes = @(20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024)
$iosDir = Join-Path $Root 'ios/AppIcon.appiconset'
Export-IconSet $mono $iosDir 'AppIcon' $iosSizes $false
foreach ($s in $iosSizes) {
    Copy-Item (Join-Path $iosDir "AppIcon-$s.png") (Join-Path $Root "ios/icon-$s.png") -Force
}

$contentsJson = @{
    images = @(
        @{ size = '20x20'; idiom = 'iphone'; filename = 'AppIcon-40.png'; scale = '2x' }
        @{ size = '20x20'; idiom = 'iphone'; filename = 'AppIcon-60.png'; scale = '3x' }
        @{ size = '29x29'; idiom = 'iphone'; filename = 'AppIcon-58.png'; scale = '2x' }
        @{ size = '29x29'; idiom = 'iphone'; filename = 'AppIcon-87.png'; scale = '3x' }
        @{ size = '40x40'; idiom = 'iphone'; filename = 'AppIcon-80.png'; scale = '2x' }
        @{ size = '40x40'; idiom = 'iphone'; filename = 'AppIcon-120.png'; scale = '3x' }
        @{ size = '60x60'; idiom = 'iphone'; filename = 'AppIcon-120.png'; scale = '2x' }
        @{ size = '60x60'; idiom = 'iphone'; filename = 'AppIcon-180.png'; scale = '3x' }
        @{ size = '20x20'; idiom = 'ipad'; filename = 'AppIcon-20.png'; scale = '1x' }
        @{ size = '20x20'; idiom = 'ipad'; filename = 'AppIcon-40.png'; scale = '2x' }
        @{ size = '29x29'; idiom = 'ipad'; filename = 'AppIcon-29.png'; scale = '1x' }
        @{ size = '29x29'; idiom = 'ipad'; filename = 'AppIcon-58.png'; scale = '2x' }
        @{ size = '40x40'; idiom = 'ipad'; filename = 'AppIcon-40.png'; scale = '1x' }
        @{ size = '40x40'; idiom = 'ipad'; filename = 'AppIcon-80.png'; scale = '2x' }
        @{ size = '76x76'; idiom = 'ipad'; filename = 'AppIcon-76.png'; scale = '1x' }
        @{ size = '76x76'; idiom = 'ipad'; filename = 'AppIcon-152.png'; scale = '2x' }
        @{ size = '83.5x83.5'; idiom = 'ipad'; filename = 'AppIcon-167.png'; scale = '2x' }
        @{ size = '1024x1024'; idiom = 'ios-marketing'; filename = 'AppIcon-1024.png'; scale = '1x' }
    )
    info = @{ version = 1; author = 'xcode' }
} | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText((Join-Path $iosDir 'Contents.json'), $contentsJson, [System.Text.UTF8Encoding]::new($false))

# Web icons
$webDir = Join-Path $Root 'web'
foreach ($s in @(16, 32)) {
    $bmp = Resize-Bitmap $mono $s $false 0.05
    Save-Png $bmp (Join-Path $webDir "favicon-${s}x${s}.png")
    $bmp.Dispose()
}
foreach ($s in @(192, 512)) {
    $bmp = Resize-Bitmap $mono $s $false
    Save-Png $bmp (Join-Path $webDir "android-chrome-${s}x${s}.png")
    $bmp.Dispose()
}
$touch = Resize-Bitmap $mono 180 $false
Save-Png $touch (Join-Path $webDir 'apple-touch-icon.png')
$touch.Dispose()

$icon16 = Join-Path $webDir 'favicon-16x16.png'
$icon32 = Join-Path $webDir 'favicon-32x32.png'
Save-Ico @($icon16, $icon32) (Join-Path $webDir 'favicon.ico')

# PWA + social
Save-OgImage $full (Join-Path $webDir 'og-image.png')
Copy-Item (Join-Path $webDir 'og-image.png') (Join-Path $webDir 'social-sharing.png') -Force
$pwa192 = Join-Path $webDir 'android-chrome-192x192.png'
$pwa512 = Join-Path $webDir 'android-chrome-512x512.png'
Copy-Item $pwa192 (Join-Path $webDir 'pwa-192x192.png') -Force
Copy-Item $pwa512 (Join-Path $webDir 'pwa-512x512.png') -Force

# General icons folder
Export-IconSet $mono (Join-Path $Root 'icons') 'xmoney' @(32, 48, 64, 128, 256) $false
Export-IconSet $full (Join-Path $Root 'icons') 'xmoney-full' @(256, 512) $false

# Splash screens
$splAndroid = Join-Path $Root 'splash/android'
$splIos = Join-Path $Root 'splash/ios'
$splWeb = Join-Path $Root 'splash/web'
Save-Splash $full 1080 1920 (Join-Path $splAndroid 'splash-portrait-1080x1920.png')
Save-Splash $full 1440 2560 (Join-Path $splAndroid 'splash-portrait-1440x2560.png')
Save-Splash $full 1280 720 (Join-Path $splAndroid 'splash-landscape-1280x720.png')
Save-Splash $full 1290 2796 (Join-Path $splIos 'splash-1290x2796.png')
Save-Splash $full 1170 2532 (Join-Path $splIos 'splash-1170x2532.png')
Save-Splash $full 1242 2688 (Join-Path $splIos 'splash-1242x2688.png')
Save-Splash $full 1920 1080 (Join-Path $splWeb 'loading-splash.png')
Copy-Item (Join-Path $splWeb 'loading-splash.png') (Join-Path $splWeb 'loading-splash-portrait.png') -Force

$master.Dispose(); $full.Dispose(); $mono.Dispose()
Write-Host "XMONEY branding assets generated under $Root"
