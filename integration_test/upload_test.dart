import 'package:android/bottom_navbar/bottom_navbar.dart';
import 'package:android/upload_file/menampilkanpdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:android/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> login(WidgetTester tester) async {
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
  await tester.pumpAndSettle(
    const Duration(seconds: 15),
    EnginePhase.sendSemanticsUpdate,
    const Duration(minutes: 1),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('Skenario setelah login berhasil', () {
    testWidgets('pengguna dapat menemukan dan menekan tombol upload', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      await login(tester);
      print("✅ Login berhasil dan halaman utama telah dimuat.");

      expect(find.byType(MyBottomNavBar), findsOneWidget);
      final uploadButtonFinder = find.byKey(const Key('upload_file_button'));
      expect(uploadButtonFinder, findsOneWidget);
      print("✅ Tombol 'Upload File' berhasil ditemukan.");

      await tester.tap(uploadButtonFinder);
      await tester.pump(const Duration(seconds: 2));

      print("✅ Tombol 'Upload File' berhasil ditekan.");
      await tester.pumpAndSettle(const Duration(seconds: 20));

      expect(find.byType(PdfViewerPage), findsOneWidget);
      print("✅ File berhasil dipilih, navigasi ke PdfViewerPage berhasil.");
      final fab = find.byKey(const Key('add_or_save_qr_button'));
      await tester.tap(fab);
      await tester.pumpAndSettle();
      print("✅ Tombol 'Tanda Tangan' ditekan, dialog seharusnya muncul.");
      await tester.enterText(
        find.byKey(const Key('tujuan_field')),
        'Tujuan Pengujian Otomatis',
      );
      await tester.enterText(
        find.byKey(const Key('nip_field')),
        '362358302012',
      );
      print("✅ Form dialog berhasil diisi.");
      await tester.tap(find.byKey(const Key('dialog_ok_button')));
      await tester.pumpAndSettle();
      print("✅ Tombol OK dialog ditekan.");

      await tester.tap(find.byKey(const Key('add_or_save_qr_button')));
      await tester.tap(fab);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      print("✅ Tombol 'Simpan Posisi QR' ditekan.");

      final sendButton = find.byKey(const Key('send_document_button'));
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(MyBottomNavBar), findsOneWidget);
      expect(find.byType(PdfViewerPage), findsNothing);
      print("✅ Dokumen berhasil dikirim dan kembali ke halaman utama.");
    });
  });
}
