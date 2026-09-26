import 'package:c4_harchuvannya/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v0.9 audit entry stays backward compatible', () {
    final entry = AuditEntry.fromJson(<String, dynamic>{
      'time': '2026-09-26T10:00:00.000',
      'actor': 'admin',
      'personId': 'p1',
      'personName': 'Тест Т.Т.',
      'group': 'С-41',
      'day': '2026-09-26',
      'meal': 'Сніданок',
      'oldValue': '',
      'newValue': 'К',
      'action': 'STATUS_SET',
    });

    expect(entry.details, isEmpty);
    expect(auditActionTitle(entry.action), 'Зміна статусу');
  });

  test('v0.9 role labels stay stable', () {
    expect(roleTitle(UserRole.admin), 'Адміністратор');
    expect(roleTitle(UserRole.editor), 'Редактор');
    expect(roleTitle(UserRole.duty), 'Черговий курсу');
  });
}
