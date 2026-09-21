import 'package:c4_harchuvannya/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('login screen opens', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = AppController();
    await controller.initialize();
    await tester.pumpWidget(C4FoodApp(controller: controller));
    expect(find.text('С4 Харчування'), findsOneWidget);
    expect(find.text('Увійти'), findsOneWidget);
  });
}
