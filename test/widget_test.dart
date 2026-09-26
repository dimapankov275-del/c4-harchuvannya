import 'package:c4_harchuvannya/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const packageInfoChannel = MethodChannel('dev.fluttercommunity.plus/package_info');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'С4 Харчування',
          'packageName': 'ua.c4.c4_harchuvannya',
          'version': '0.9.0',
          'buildNumber': '15',
          'buildSignature': '',
          'installerStore': null,
        };
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, null);
  });

  testWidgets('login screen opens', (WidgetTester tester) async {
    final now = DateTime.now().toIso8601String();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'last_update_check': now,
      'last_auto_backup': now,
    });

    final controller = AppController();
    await controller.initialize();

    await tester.pumpWidget(C4FoodApp(controller: controller));
    await tester.pump();

    expect(find.text('С4 Харчування'), findsOneWidget);
    expect(find.text('Увійти'), findsOneWidget);
  });
}
