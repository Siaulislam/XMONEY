# Creates standard Android mipmap folders from generated launcher icons.
$root = "$PSScriptRoot\..\assets\android"
$map = @{
    'mipmap-mdpi' = 48
    'mipmap-hdpi' = 72
    'mipmap-xhdpi' = 96
    'mipmap-xxhdpi' = 144
    'mipmap-xxxhdpi' = 192
}
foreach ($entry in $map.GetEnumerator()) {
    $dir = Join-Path $root $entry.Key
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Copy-Item (Join-Path $root "ic_launcher-$($entry.Value).png") (Join-Path $dir 'ic_launcher.png') -Force
    Copy-Item (Join-Path $root "ic_launcher_round-$($entry.Value).png") (Join-Path $dir 'ic_launcher_round.png') -Force
}
Copy-Item (Join-Path $root 'ic_launcher-512.png') (Join-Path $root 'playstore-icon-512.png') -Force
Write-Host 'Android mipmap folders prepared under assets/android/'
