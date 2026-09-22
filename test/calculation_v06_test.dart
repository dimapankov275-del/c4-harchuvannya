import 'package:c4_harchuvannya/main.dart';
import 'package:flutter_test/flutter_test.dart';

Person person(String id, String name) => Person(
      id: id,
      rank: 'солдат',
      name: name,
      group: 'С-41',
    );

void main() {
  group('v0.6 calculations', () {
    test('190+ is counted only inside K', () {
      final controller = AppController();
      final day = DateTime(2026, 9, 23);
      final special = person('1', "Зінов'єв В.Е.");
      final regular = person('2', 'Іваненко І.І.');
      final specialEating = person('3', 'Остапчук М.О.');

      special.setMark(day, Meal.breakfast, Mark.k);
      regular.setMark(day, Meal.breakfast, Mark.k);
      controller.people = <Person>[special, regular, specialEating];

      final counts = controller.countsFor(day, Meal.breakfast);
      expect(counts.k, 2);
      expect(counts.k190Plus, 1);
      expect(controller.buildMessage1(day), contains('(2К, з них 1 190+)'));
    });

    test('190+ text is hidden when no special person has K', () {
      final controller = AppController();
      final day = DateTime(2026, 9, 23);
      final regular = person('1', 'Іваненко І.І.');
      final specialEating = person('2', 'Несенюк І.В.');

      regular.setMark(day, Meal.lunch, Mark.k);
      controller.people = <Person>[regular, specialEating];

      final message = controller.buildMessage1(day);
      expect(message, contains('Обід - 1 (1К)'));
      expect(message, isNot(contains('190+')));
    });

    test('apostrophe variants match 190+ list', () {
      final controller = AppController();
      final day = DateTime(2026, 9, 23);
      final special = person('1', 'Зінов’єв В.Е.');
      special.setMark(day, Meal.dinner, Mark.k);
      controller.people = <Person>[special];

      expect(controller.countsFor(day, Meal.dinner).k190Plus, 1);
    });

    test('multi-day range preserves every day', () {
      final controller = AppController();
      final start = DateTime(2026, 9, 30);
      final end = DateTime(2026, 10, 2);
      controller.people = <Person>[person('1', 'Іваненко І.І.')];

      final message = controller.buildMessage1Range(start, end);
      expect(message, contains('30.09'));
      expect(message, contains('01.10'));
      expect(message, contains('02.10'));
    });

    test('server message gets 190+ annotation without changing K total', () {
      final controller = AppController();
      final day = DateTime(2026, 9, 23);
      final special = person('1', 'Покормяхо В.І.');
      special.setMark(day, Meal.breakfast, Mark.k);
      controller.people = <Person>[special];

      const server = '23.09\n\nСніданок - 73 (31К) (23 відрядження, 1 шпиталь)\nОбід - 102 (2К)';
      final result = controller.add190PlusToMessage1(server, day, day);

      expect(result, contains('Сніданок - 73 (31К, з них 1 190+)'));
      expect(result, contains('Обід - 102 (2К)'));
    });
  });
}
