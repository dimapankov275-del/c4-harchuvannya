import 'package:c4_harchuvannya/report_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('v0.8.1 compensation report text', () {
    test('lists only marked meals by date', () {
      final text = ReportService.formatCompensation(<MealCompensationDay>[
        MealCompensationDay(day: DateTime(2026, 9, 23), breakfast: true, lunch: false, dinner: true),
        MealCompensationDay(day: DateTime(2026, 9, 24), breakfast: false, lunch: true, dinner: false),
      ]);
      expect(text, 'сніданок, вечерю 23 вересня, обід 24 вересня 2026 року');
    });

    test('compresses a continuous full-meal period', () {
      final text = ReportService.formatCompensation(<MealCompensationDay>[
        MealCompensationDay(day: DateTime(2026, 9, 23), breakfast: true, lunch: true, dinner: true),
        MealCompensationDay(day: DateTime(2026, 9, 24), breakfast: true, lunch: true, dinner: true),
        MealCompensationDay(day: DateTime(2026, 9, 25), breakfast: true, lunch: true, dinner: true),
      ]);
      expect(
        text,
        'сніданок, обід, вечерю у період з 23 вересня по 25 вересня 2026 року',
      );
    });

    test('ignores days without K meals', () {
      final text = ReportService.formatCompensation(<MealCompensationDay>[
        MealCompensationDay(day: DateTime(2026, 9, 23), breakfast: false, lunch: false, dinner: false),
        MealCompensationDay(day: DateTime(2026, 9, 24), breakfast: true, lunch: false, dinner: false),
      ]);
      expect(text, 'сніданок 24 вересня 2026 року');
    });
  });
}
