# С4 Харчування v0.2.1 — інсталяційні пакети

Цей проєкт підготовлений для автоматичної збірки трьох інсталяційних пакетів:

- `C4_Harchuvannya_v0.2.1_Setup.exe` — Windows x64, інсталятор Inno Setup.
- `C4_Harchuvannya_v0.2.1_Android.apk` — Android APK для ручного встановлення.
- `C4_Harchuvannya_v0.2.1_macOS.dmg` — macOS DMG.

## Найпростіше: GitHub Actions

У репозиторії є `.github/workflows/release-installers.yml`.
Після запуску workflow GitHub використовує окремо Windows, Linux та macOS build runners і видає три готові artifacts.

## Локальна збірка Windows

Потрібні Flutter + Visual Studio Desktop development with C++ + Inno Setup 6.
Запустити:

`scripts\\build_windows_installer.bat`

Готовий інсталятор:

`installer\\windows\\output\\C4_Harchuvannya_v0.2.1_Setup.exe`

## Локальна збірка Android

Потрібні Flutter + Android SDK.
Запустити:

`scripts\\build_android_apk.bat`

Готовий APK:

`C4_Harchuvannya_v0.2.1_Android.apk`

## Важливо про APK

Поточна v0.2.x — тестова UI-версія. GitHub workflow використовує стандартне Flutter release signing template для тестової збірки. Для стабільних оновлень на реальних пристроях перед v1.0 потрібно створити постійний приватний Android signing key і зберігати його поза репозиторієм (наприклад у GitHub Secrets).

## Важливо про Windows/macOS

Перші тестові збірки можуть показувати системне попередження, оскільки вони ще не підписані комерційним code-signing сертифікатом. Перед публічним релізом Windows інсталятор потрібно підписати, а macOS `.app/.dmg` — підписати і нотаризувати через Apple Developer.
