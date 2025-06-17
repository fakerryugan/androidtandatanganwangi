// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:qr/qr.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'package:android/upload_file/menampilkanpdf.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// class QrPdfHelper {
//   static Future<void> insertQrToPdfDirectly({
//     required BuildContext context,
//     required String filePath,
//     required String fullUrl,
//     required int page,
//     required Offset offset,
//     required GlobalKey pdfViewerKey,
//     required PdfViewerController pdfViewerController,
//     required int documentId,
//     double qrPdfSize = 100.0,
//   }) async {
//     final fileBytes = await File(filePath).readAsBytes();
//     final PdfDocument document = PdfDocument(inputBytes: fileBytes);

//     final QrPainter qrPainter = QrPainter.withQr(
//       qr: QrValidator.validate(
//         data: fullUrl,
//         version: QrVersions.auto,
//         errorCorrectionLevel: QrErrorCorrectLevel.H,
//       ).qrCode!,
//       gapless: true,
//       color: const Color(0xFF000000),
//       emptyColor: const Color(0xFFFFFFFF),
//     );

//     final ui.Image qrImage = await qrPainter.toImage((qrPdfSize * 3));
//     final ByteData? byteData = await qrImage.toByteData(
//       format: ui.ImageByteFormat.png,
//     );
//     if (byteData == null)
//       throw Exception('Failed to convert QR image to bytes.');
//     final Uint8List bytes = byteData.buffer.asUint8List();
//     final PdfBitmap pdfImage = PdfBitmap(bytes);

//     final int pageIndex = page - 1;
//     if (pageIndex < 0 || pageIndex >= document.pages.count) {
//       throw Exception('Invalid page number: $page');
//     }
//     final PdfPage pdfPage = document.pages[pageIndex];

//     final renderBox =
//         pdfViewerKey.currentContext!.findRenderObject() as RenderBox;
//     final Size viewerSize = renderBox.size;
//     final double zoom = pdfViewerController.zoomLevel;

//     // Hitung posisi di PDF
//     double pdfX = offset.dx * (pdfPage.size.width / (viewerSize.width * zoom));
//     double pdfY =
//         offset.dy * (pdfPage.size.height / (viewerSize.height * zoom));

//     // Clamp supaya tidak keluar halaman
//     pdfX = pdfX.clamp(0.0, pdfPage.size.width - qrPdfSize);
//     pdfY = pdfY.clamp(0.0, pdfPage.size.height - qrPdfSize);

//     pdfPage.graphics.drawImage(
//       pdfImage,
//       Rect.fromLTWH(pdfX, pdfY, qrPdfSize, qrPdfSize),
//     );

//     await File(filePath).writeAsBytes(await document.save());
//     document.dispose();

//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => PdfViewerPage(
//           filePath: filePath,
//           documentId: documentId,
//           accessToken: '',
//         ),
//       ),
//     );
//   }
// }
