$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

& (Join-Path $PSScriptRoot 'prepare_flutter_project.ps1')
flutter analyze
flutter test
flutter build apk --release

$src = Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk'
$dst = Join-Path $root 'C4_Harchuvannya_v0.2.1_Android.apk'
Copy-Item $src $dst -Force
Write-Host "Готово: $dst" -ForegroundColor Green
