# C4 Harchuvannya — Release checklist v1.0.0

1. `flutter pub get`
2. `flutter analyze --no-fatal-infos`
3. `flutter test`
4. Перевірити вручну Windows:
   - login;
   - синхронізацію;
   - К/В/Ш/Вд;
   - розрахунок на 1 день і період;
   - 190+;
   - формування DOCX;
   - «Мою тестову сторінку Word»;
   - backup/restore;
   - журнал;
   - ролі;
   - CSV export/import у локальному режимі.
5. Commit: `v1.0 stable release`
6. Push `main` і дочекатися зеленого `Build C4 Harchuvannya Installers`.
7. Створити tag `v1.0.0` на тому самому зеленому commit.
8. Push tag `v1.0.0`.
9. Перевірити GitHub Release:
   - `C4_Harchuvannya_v1.0.0_Setup.exe`
   - `C4_Harchuvannya_v1.0.0_Android.apk`
   - `C4_Harchuvannya_v1.0.0_macOS.dmg`
   - `update-policy.json`
   - `SHA256SUMS.txt`
10. Встановити Windows Setup поверх попередньої версії й перевірити, що локальні дані та Word-шаблон збережені.
