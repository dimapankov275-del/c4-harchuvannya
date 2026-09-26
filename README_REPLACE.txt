C4 ХАРЧУВАННЯ — v1.0.0+16 STABLE

Це стабільний реліз 1.0 на базі успішної v0.9.

ЩО ЗРОБИТИ
1. Розпакуй цей архів у корінь репозиторію c4-harchuvannya.
2. Погодься на заміну файлів.
3. Перевір, що додались:
   - CHANGELOG_v1.0.md
   - test/release_v1_test.dart
4. Запусти:
   flutter pub get
   flutter analyze --no-fatal-infos
   flutter test
5. Commit:
   v1.0 stable release
6. Push origin.
7. Після успішного GitHub Actions створи tag v1.0.0 і push tag.

ЩО НЕ ЗМІНЮВАЛОСЬ
- Apps Script не треба оновлювати.
- «Моя тестова сторінка Word» і твоє ручне Word-оформлення збережені.
- Логіка розрахунків, 190+, DOCX, ролей, журналу, backup та CSV збережена.

ЩО НОВОГО В РЕЛІЗНІЙ ЧАСТИНІ
- Версія 1.0.0+16.
- Windows / Android / macOS пакети називаються v1.0.0.
- GitHub Release публікується з CHANGELOG_v1.0.md.
- Tag перевіряється проти pubspec.yaml.
- Regression-тест перевіряє узгодженість усіх номерів версій.
