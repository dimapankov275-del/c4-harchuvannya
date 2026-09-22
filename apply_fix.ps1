$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
$target = Join-Path $repo "lib\main.dart"

if (-not (Test-Path $target)) {
    Write-Host ""
    Write-Host "ПОМИЛКА: не знайдено lib\main.dart" -ForegroundColor Red
    Write-Host "Розпакуйте FIX у корінь репозиторію c4-harchuvannya і запустіть ще раз."
    Read-Host "Натисніть Enter"
    exit 1
}

$content = [System.IO.File]::ReadAllText($target)
$content = $content.Replace("`r`n", "`n")

if ($content.Contains("int _appNoticeSequence = 0;")) {
    Write-Host ""
    Write-Host "FIX вже встановлений." -ForegroundColor Green
    Read-Host "Натисніть Enter"
    exit 0
}

$old = @'
const Duration appNoticeDuration = Duration(seconds: 5);

void showAppNotice(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: appNoticeDuration,
      backgroundColor: backgroundColor,
      action: action,
    ),
  );
}
'@

$new = @'
const Duration appNoticeDuration = Duration(seconds: 5);
int _appNoticeSequence = 0;

void showAppNotice(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final noticeSequence = ++_appNoticeSequence;

  // Нове повідомлення одразу прибирає попереднє.
  messenger.clearSnackBars();

  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: appNoticeDuration,
      backgroundColor: backgroundColor,
      action: action,
    ),
  );

  // У Flutter SnackBar з SnackBarAction може не закриватися автоматично
  // в режимі доступності. Тому примусово закриваємо саме актуальне
  // повідомлення через 5 секунд.
  Timer(appNoticeDuration, () {
    if (noticeSequence != _appNoticeSequence) return;
    if (!messenger.mounted) return;
    messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
  });
}
'@

if (-not $content.Contains($old)) {
    Write-Host ""
    Write-Host "ПОМИЛКА: потрібний блок showAppNotice не знайдено." -ForegroundColor Red
    Write-Host "Переконайтесь, що у вас гілка main з версією 0.5.x."
    Read-Host "Натисніть Enter"
    exit 1
}

$content = $content.Replace($old, $new)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($target, $content, $utf8NoBom)

Write-Host ""
Write-Host "ГОТОВО: FIX 5 секунд застосовано до lib\main.dart" -ForegroundColor Green
Write-Host "Тепер відкрийте GitHub Desktop -> Commit -> Push origin."
Write-Host ""
Read-Host "Натисніть Enter"
