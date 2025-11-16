import 'dart:io';
import 'package:android/features/dashboard/view/dashboard_page.dart';
import 'package:android/upload_file/menampilkanpdf.dart';
import 'package:android/upload_file/generateqr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:android/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:file_picker/file_picker.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('Skenario Tes Alur Upload File', () {
    Future<void> _loginUser(WidgetTester tester) async {
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

      expect(find.byType(DashboardPage), findsOneWidget);
    }

    Future<void> _performUpload(WidgetTester tester) async {
      final uploadButtonFinder = find.byKey(const Key('upload_file_button'));
      expect(uploadButtonFinder, findsOneWidget);

      await tester.tap(uploadButtonFinder);

      print('--- PERHATIAN: PILIH FILE PDF SECARA MANUAL SEKARANG ---');
      await tester.pumpAndSettle(const Duration(seconds: 30));

      expect(find.byType(PdfViewerPage), findsOneWidget);
      expect(find.byType(DashboardPage), findsNothing);
    }

    Future<void> _addSignatureAndVerify(WidgetTester tester) async {
      final signButtonFinder = find.byKey(const Key('add_or_save_qr_button'));
      expect(signButtonFinder, findsOneWidget);
      expect(find.text('Tanda Tangan'), findsOneWidget);

      await tester.tap(signButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byKey(const Key('tujuan_field')), findsOneWidget);
      expect(find.byKey(const Key('nip_field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('tujuan_field')),
        'Tes Tujuan Upload Manual',
      );
      await tester.enterText(
        find.byKey(const Key('nip_field')),
        '362358302012',
      );

      await tester.tap(find.byKey(const Key('dialog_ok_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Simpan Posisi QR'), findsOneWidget);
      expect(find.text('Tanda Tangan'), findsNothing);
    }

    testWidgets(
      'Login, upload file, dan tambahkan tanda tangan',
      (WidgetTester tester) async {
        await _loginUser(tester);
        await _performUpload(tester);
        await _addSignatureAndVerify(tester);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}
