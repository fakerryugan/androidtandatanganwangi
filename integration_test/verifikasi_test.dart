import 'package:android/features/dashboard/view/dashboard_page.dart';
import 'package:android/features/verification/view/fileverifikasipage.dart';
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

  group('Skenario Tes Alur Verifikasi TTD', () {
    testWidgets(
      'Login berhasil dan navigasi ke halaman Verifikasi TTD',
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

        final verificationButton = find.byKey(
          const Key('verifikasi_ttd_button'),
        );
        expect(verificationButton, findsOneWidget);

        await tester.tap(verificationButton);

        await tester.pumpAndSettle();

        expect(find.byType(FileVerifikasiPage), findsOneWidget);
        expect(find.byType(DashboardPage), findsNothing);

        expect(find.text('Dokumen Perlu Verifikasi'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'Cari file...'), findsOneWidget);

        await tester.pumpAndSettle(const Duration(seconds: 3));
        expect(find.byType(CircularProgressIndicator), findsNothing);

        final searchField = find.widgetWithText(TextField, 'Cari file...');
        await tester.enterText(searchField, 'tes cari');
        await tester.pumpAndSettle(const Duration(milliseconds: 500));

        expect(find.text('tes cari'), findsOneWidget);
      },
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });
}
