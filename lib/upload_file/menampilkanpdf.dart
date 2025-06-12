import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr/qr.dart';
import 'package:android/upload_file/generateqr.dart';

class PdfViewerPage extends StatefulWidget {
  final String filePath;

  const PdfViewerPage({Key? key, required this.filePath}) : super(key: key);

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final TextEditingController nipController = TextEditingController();
  final TextEditingController tujuanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? currentQrData;
  bool waitingForTap = false;

  @override
  void dispose() {
    nipController.dispose();
    tujuanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.filePath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit PDF', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF172B4C),
        centerTitle: true,
        leading: const SizedBox(),
      ),
      body: GestureDetector(
        onTapDown: (details) async {
          if (waitingForTap && currentQrData != null) {
            final renderBox =
                _pdfViewerKey.currentContext!.findRenderObject() as RenderBox;
            final localPosition = renderBox.globalToLocal(
              details.globalPosition,
            );
            final adjustedOffset = Offset(
              localPosition.dx,
              localPosition.dy - kToolbarHeight,
            );

            final pageNumber = pdfViewerController.pageNumber;

            await insertQrToPdfDirectly(
              data: currentQrData!,
              page: pageNumber,
              offset: adjustedOffset,
            );

            setState(() {
              currentQrData = null;
              waitingForTap = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('QR berhasil disimpan ke PDF')),
            );
          }
        },
        child: SfPdfViewer.file(
          file,
          key: _pdfViewerKey,
          controller: pdfViewerController,
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.white,
          onPressed: () async {
            final result = await showInputDialog(
              context: context,
              formKey: _formKey,
              nipController: nipController,
              tujuanController: tujuanController,
              showTujuan: true,
            );

            if (result != null && result['encrypted_link'] != null) {
              setState(() {
                currentQrData = result['encrypted_link'];
                waitingForTap = true;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Silakan klik posisi di halaman PDF.'),
                ),
              );
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          label: const Text(
            '+ Tanda tangan',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }

  Future<void> insertQrToPdfDirectly({
    required String data,
    required int page,
    required Offset offset,
  }) async {
    final fileBytes = await File(widget.filePath).readAsBytes();
    final document = PdfDocument(inputBytes: fileBytes);

    final qrImage = await QrPainter.withQr(
      qr: QrValidator.validate(
        data:
            'http://fakerryugan.my.id/api/signature/view-from-payload?payload=$data',
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      ).qrCode!,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    ).toImage(200);

    final byteData = await qrImage.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    final pdfImage = PdfBitmap(bytes);

    final pageIndex = page - 1;
    document.pages[pageIndex].graphics.drawImage(
      pdfImage,
      Rect.fromLTWH(offset.dx, offset.dy, 100, 100),
    );

    final outputPath = '${widget.filePath}_signed.pdf';
    final file = File(outputPath);
    await file.writeAsBytes(await document.save());
    document.dispose();

    // Tampilkan PDF yang sudah diupdate
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PdfViewerPage(filePath: outputPath)),
    );
  }
}
