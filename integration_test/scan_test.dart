import 'package:android/features/dashboard/view/dashboard_page.dart';
import 'package:android/features/scan/view/scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:android/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('Skenario Tes Alur Dashboard', () {
    testWidgets(
      'Login berhasil dan navigasi ke halaman Scan QR',
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

        final scanButtonFinder = find.byKey(const Key('scan_qr_button'));
        expect(scanButtonFinder, findsOneWidget);

        await tester.tap(scanButtonFinder);

        await tester.pumpAndSettle();

        expect(find.byType(BarcodeScannerPage), findsOneWidget);

        expect(find.byType(DashboardPage), findsNothing);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });
}
