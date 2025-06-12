import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

Future<String> insertQrToPdf({
  required String filePath,
  required List<String> qrDataList,
  required List<Offset> qrPositions,
  required List<int> qrPages,
}) async {
  final file = File(filePath);
  final bytes = await file.readAsBytes();
  final document = PdfDocument(inputBytes: bytes);

  for (int i = 0; i < qrDataList.length; i++) {
    final pageIndex = qrPages[i];
    if (pageIndex < 0 || pageIndex >= document.pages.count) continue;

    final page = document.pages[pageIndex];

    final painter = QrPainter(
      data: qrDataList[i],
      version: QrVersions.auto,
      gapless: true,
    );

    final picData = await painter.toImageData(300); // resolusi tinggi
    final image = PdfBitmap(picData!.buffer.asUint8List());

    final size = 100.0; // <-- Ukuran QR code statis
    final x = qrPositions[i].dx * page.getClientSize().width;
    final y = qrPositions[i].dy * page.getClientSize().height;

    page.graphics.drawImage(image, Rect.fromLTWH(x, y, size, size));
  }

  final output = await getTemporaryDirectory();
  final outputFile = File(
    "${output.path}/signed_${DateTime.now().millisecondsSinceEpoch}.pdf",
  );
  await outputFile.writeAsBytes(document.save() as List<int>);
  document.dispose();

  return outputFile.path;
}

Future<void> uploadReplacedPdf(
  String documentId,
  String token,
  String filePath,
  BuildContext context,
) async {
  final uri = Uri.parse('http://fakerryugan.my.id/api/documents/replace');
  final request = http.MultipartRequest('POST', uri);

  request.fields['document_id'] = documentId;
  request.headers['Authorization'] = 'Bearer $token';

  final file = await http.MultipartFile.fromPath('file', filePath);
  request.files.add(file);

  final response = await request.send();

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dokumen berhasil diperbarui!')),
    );
    Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal upload. Kode: ${response.statusCode}')),
    );
  }
}
