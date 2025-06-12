import 'dart:io';
import 'dart:ui' as ui;
import 'package:android/api/token.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr/qr.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

Future<String> insertQrToPdf({
  required String filePath,
  required List<String> qrDataList,
  required List<Offset> qrPositions,
  required List<int> qrPages,
}) async {
  final fileBytes = await File(filePath).readAsBytes();
  final document = syncfusion.PdfDocument(inputBytes: fileBytes);

  for (int i = 0; i < qrDataList.length; i++) {
    final qrImage = await QrPainter.withQr(
      qr: QrValidator.validate(
        data: '$baseUrl/signature/view-from-payload?payload=${qrDataList[i]}',
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      ).qrCode!,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    ).toImage(200);

    final byteData = await qrImage.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final pdfImage = syncfusion.PdfBitmap(bytes);

    final page = document.pages[qrPages[i]];
    final pageSize = page.getClientSize();

    final pdfX = qrPositions[i].dx * pageSize.width;
    final pdfY = pageSize.height - (qrPositions[i].dy * pageSize.height) - 100;

    page.graphics.drawImage(pdfImage, Rect.fromLTWH(pdfX, pdfY, 100, 100));
  }

  final tempPath = '${filePath}_signed_temp.pdf';
  final file = File(tempPath);
  await file.writeAsBytes(await document.save());
  document.dispose();
  return tempPath;
}

Future<void> uploadReplacedPdf(
  String documentId,
  String accessToken,
  String filePath,
  BuildContext context,
) async {
  final uri = Uri.parse('$baseUrl/documents/replace/$documentId');

  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $accessToken'
    ..files.add(await http.MultipartFile.fromPath('new_file', filePath));

  final response = await request.send();

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berhasil mengganti PDF di server')),
    );
  } else {
    final respStr = await response.stream.bytesToString();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Gagal upload: $respStr')));
  }
}
