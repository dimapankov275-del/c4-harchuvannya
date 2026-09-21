$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

& (Join-Path $PSScriptRoot 'prepare_flutter_project.ps1')
flutter analyze
flutter test
flutter build windows --release

$isccCandidates = @(
  "$env:ProgramFiles(x86)\Inno Setup 6\ISCC.exe",
  "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
)
$iscc = $isccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) {
  throw 'Inno Setup 6 не знайдено. Встановіть Inno Setup 6 і повторіть запуск.'
}

& $iscc (Join-Path $root 'installer\windows\C4_Harchuvannya.iss')
$setup = Join-Path $root 'installer\windows\output\C4_Harchuvannya_v0.2.1_Setup.exe'
Write-Host "Готово: $setup" -ForegroundColor Green
