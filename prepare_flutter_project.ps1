$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter не знайдено у PATH.'
}

flutter create --platforms=android,windows,macos --org ua.c4 --project-name c4_harchuvannya .
flutter pub get

# Людська назва Android-застосунку.
$manifest = Join-Path $root 'android\app\src\main\AndroidManifest.xml'
if (Test-Path $manifest) {
  $text = Get-Content $manifest -Raw -Encoding UTF8
  $text = $text -replace 'android:label="c4_harchuvannya"', 'android:label="С4 Харчування"'
  Set-Content $manifest $text -Encoding UTF8
}

Write-Host 'Проєкт підготовлено.' -ForegroundColor Green
