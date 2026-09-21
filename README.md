# С4 Харчування v0.2.0 — UI Preview

Це друга версія клієнта, повністю перероблена під затверджений сучасний інтерфейс.

## Що перевірити найперше

Відкрий:

`prototype/index.html`

Демо:

`admin / admin123`

Прототип працює локально у браузері та показує майже фінальну візуальну структуру
для ноутбука і телефона.

## Що вже є у Flutter-проєкті

- авторизація;
- ролі admin / editor / duty;
- adaptive desktop/mobile shell;
- темна / світла тема;
- головний dashboard;
- особовий склад;
- статуси К / В / Ш / Вд;
- масове проставлення;
- окремі Шпиталь / Відрядження;
- розрахунки;
- Telegram demo;
- Word / Excel demo;
- історія;
- користувачі для адміністратора;
- локальні демо-дані / offline demo.

## Важливо

Це UI-preview. Бойове підключення до Google Sheets / Apps Script API буде окремим етапом.
Основна Google Таблиця на цьому етапі не змінюється.

## Запуск Flutter

Після встановлення Flutter SDK:

```powershell
flutter create --platforms=android,windows,macos --org ua.c4 .
flutter pub get
flutter run -d windows
```

Android release:

```powershell
flutter build apk --release
```

Windows release:

```powershell
flutter build windows --release
```

macOS release потрібно збирати на macOS/Xcode.
