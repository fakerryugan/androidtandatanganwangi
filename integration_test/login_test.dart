import 'package:android/features/dashboard/view/dashboard_page.dart';
import 'package:android/features/scan/repository/scanner_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:android/main.dart' as app;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([ScannerRepository])
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

        await tester.pumpAndSettle(const Duration(seconds: 5));

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
        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.text('Login Gagal'), findsOneWidget);

        await tester.tap(find.byKey(const Key('okkk')));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );

    testWidgets(
      'Login seharusnya berhasil dengan kredensial yang valid dan navigasi ke home',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));
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
        await tester.pumpAndSettle(const Duration(seconds: 5));
        expect(find.byKey(const Key('username_field')), findsNothing);
        expect(find.byType(DashboardPage), findsOneWidget);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });
}
