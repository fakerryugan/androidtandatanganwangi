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
  Offset? qrPosition;
  bool waitingForTap = false;
  bool qrLocked = false;

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
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) {
              if (waitingForTap && currentQrData != null && !qrLocked) {
                final renderBox =
                    _pdfViewerKey.currentContext!.findRenderObject()
                        as RenderBox;
                final localPosition = renderBox.globalToLocal(
                  details.globalPosition,
                );
                final adjustedOffset = Offset(
                  localPosition.dx,
                  localPosition.dy - kToolbarHeight,
                );

                setState(() {
                  qrPosition = adjustedOffset;
                });
              }
            },
            child: SfPdfViewer.file(
              file,
              key: _pdfViewerKey,
              controller: pdfViewerController,
            ),
          ),
          if (qrPosition != null && currentQrData != null)
            Positioned(
              left: qrPosition!.dx,
              top: qrPosition!.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  if (!qrLocked) {
                    setState(() {
                      qrPosition = Offset(
                        qrPosition!.dx + details.delta.dx,
                        qrPosition!.dy + details.delta.dy,
                      );
                    });
                  }
                },
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      color: Colors.white,
                      child: QrImageView(
                        data:
                            "http://fakerryugan.my.id/api/signature/view-from-payload?payload=$currentQrData",
                        version: QrVersions.auto,
                      ),
                    ),
                    if (!qrLocked)
                      IconButton(
                        icon: const Icon(Icons.lock, color: Colors.black),
                        onPressed: () async {
                          final pageNumber = pdfViewerController.pageNumber;
                          await insertQrToPdfDirectly(
                            data: currentQrData!,
                            page: pageNumber,
                            offset: qrPosition!,
                          );

                          setState(() {
                            qrLocked = true;
                            waitingForTap = false;
                            currentQrData = null;
                            qrPosition = null;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('QR berhasil disimpan ke PDF'),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
        ],
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
                qrLocked = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Silakan tap posisi di PDF untuk menambahkan QR.',
                  ),
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
    final pdfPage = document.pages[pageIndex];

    // ✅ Hitung rasio skala tampilan viewer ke page PDF
    final viewerBox =
        _pdfViewerKey.currentContext!.findRenderObject() as RenderBox;
    final pageSize = pdfPage.size;

    // Ambil tinggi viewer dan tinggi halaman PDF
    final renderSize = viewerBox.size;

    final scaleX = pageSize.width / renderSize.width;
    final scaleY = pageSize.height / renderSize.height;

    // 💡 Koreksi posisi Y karena origin PDF di kiri bawah, bukan kiri atas
    final correctedY = renderSize.height - offset.dy;

    // Konversi koordinat layar ke koordinat PDF
    final pdfX = offset.dx * scaleX;
    final pdfY = correctedY * scaleY;

    pdfPage.graphics.drawImage(pdfImage, Rect.fromLTWH(pdfX, pdfY, 100, 100));

    final outputPath = '${widget.filePath}_signed.pdf';
    final file = File(outputPath);
    await file.writeAsBytes(await document.save());
    document.dispose();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PdfViewerPage(filePath: outputPath)),
    );
  }
}
