# Merge shared enterprise i18n into mobile-app (preserves mobile-only nav keys).
$root = "$PSScriptRoot\.."
$sharedDir = Join-Path $root 'shared\ui\i18n'
$mobileDir = Join-Path $root 'mobile-app\assets\i18n'

$mobileOnly = @{
  en = @{
    'nav.home' = 'Home'
    'nav.history' = 'History'
    'nav.more' = 'More'
    'nav.register' = 'Create account'
  }
  ar = @{
    'nav.home' = 'الرئيسية'
    'nav.history' = 'السجل'
    'nav.more' = 'المزيد'
    'nav.register' = 'إنشاء حساب'
  }
  ur = @{
    'nav.home' = 'ہوم'
    'nav.history' = 'تاریخ'
    'nav.more' = 'مزید'
    'nav.register' = 'اکاؤنٹ بنائیں'
  }
}

New-Item -ItemType Directory -Path $mobileDir -Force | Out-Null

foreach ($lang in @('en', 'ar', 'ur')) {
  $sharedPath = Join-Path $sharedDir "$lang.json"
  $outPath = Join-Path $mobileDir "$lang.json"
  $shared = Get-Content $sharedPath -Raw | ConvertFrom-Json
  $merged = @{}
  $shared.PSObject.Properties | ForEach-Object { $merged[$_.Name] = $_.Value }
  foreach ($entry in $mobileOnly[$lang].GetEnumerator()) {
    $merged[$entry.Key] = $entry.Value
  }
  ($merged | ConvertTo-Json -Depth 5) | Set-Content $outPath -Encoding UTF8
}

Write-Host 'Mobile i18n synced from shared/ui/i18n (mobile nav keys preserved).'
