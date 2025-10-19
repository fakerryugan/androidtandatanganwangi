import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:android/main.dart' as app;
import 'package:android/bottom_navbar/bottom_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('Skenario Tes Alur Login', () {
    testWidgets(
      'Login seharusnya gagal dengan kredensial salah dan menampilkan dialog error',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 10));
        await tester.tap(find.byKey(const Key('login_button_awal')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('username_field')),
          'username_salah',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'password_salah',
        );

        await tester.tap(find.byKey(const Key('login_button_masuk')));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Login Gagal'), findsOneWidget);
        await tester.tap(find.byKey(const Key('okkk')));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Login seharusnya berhasil dengan kredensial yang valid dan navigasi ke home',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('login_button_awal')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('username_field')),
          '362358302012',
        );
        await tester.enterText(
          find.byKey(const Key('password_field')),
          'Poliwangi123',
        );
        await tester.tap(find.byKey(const Key('login_button_masuk')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('username_field')), findsNothing);
        expect(find.byType(MyBottomNavBar), findsOneWidget);
      },
    );
  });
}
