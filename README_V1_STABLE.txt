C4 ХАРЧУВАННЯ — v1.0.0 STABLE

Це повний комплект для переходу з успішної v0.9 на стабільну v1.0.

ЩО РОБИТИ
1. Розпакувати ZIP у корінь репозиторію.
2. Погодитися на заміну файлів.
3. Переконатися, що додався test/release_v1_test.dart і CHANGELOG_v1.0.md.
4. Запустити:
   flutter pub get
   flutter analyze --no-fatal-infos
   flutter test
5. Commit: v1.0 stable release
6. Push origin.
7. Після успішного build створити tag v1.0.0 і push tag — release workflow збере та опублікує Setup/APK/DMG.

ВАЖЛИВО
- Apps Script у v1.0 змінювати не потрібно.
- Моя тестова сторінка Word та її логіка не змінені.
- Розрахунки, 190+, журнал, backup, ролі та CSV збережені.
- update-policy лишається non-mandatory.
