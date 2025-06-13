import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr/qr.dart';

// Sesuaikan path ini jika letak file Anda berbeda
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
  Offset? qrPosition; // Posisi QR di layar (widget)
  int? qrPageNumber; // Halaman PDF tempat QR akan disisipkan (1-indexed)
  bool waitingForTap = false; // Menunggu pengguna tap untuk menempatkan QR
  bool qrLocked =
      false; // Menandakan QR sudah ditempatkan dan siap disimpan permanen

  // Ukuran QR code di layar dan di PDF
  static const double qrDisplaySize = 100.0; // Ukuran QR di UI (untuk drag)
  static const double qrPdfSize =
      100.0; // Ukuran QR saat disisipkan ke PDF (dalam points)

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
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: waitingForTap && !qrLocked
                ? (details) {
                    setState(() {
                      qrPosition = details.localPosition;
                      qrPageNumber = pdfViewerController.pageNumber;
                      waitingForTap = false;
                    });
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'QR Code ditempatkan. Anda bisa menggesernya atau tekan kunci.',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                : null,
            child: SfPdfViewer.file(
              file,
              key: _pdfViewerKey,
              controller: pdfViewerController,
            ),
          ),
          if (qrPosition != null && currentQrData != null && !qrLocked)
            Positioned(
              left: qrPosition!.dx.clamp(
                0.0,
                MediaQuery.of(context).size.width - qrDisplaySize,
              ),
              top: qrPosition!.dy.clamp(
                0.0,
                MediaQuery.of(context).size.height - qrDisplaySize,
              ),
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
                      width: qrDisplaySize,
                      height: qrDisplaySize,
                      color: Colors.white,
                      child: QrImageView(
                        data:
                            "http://fakerryugan.my.id/api/signature/view-from-payload?payload=$currentQrData",
                        version: QrVersions.auto,
                        size: qrDisplaySize,
                        padding: const EdgeInsets.all(5.0),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.lock,
                        color: Colors.black,
                        size: 24,
                      ),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Menyimpan QR ke PDF...'),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        await insertQrToPdfDirectly(
                          data: currentQrData!,
                          page: qrPageNumber!,
                          offset: qrPosition!,
                        );

                        setState(() {
                          qrLocked = true;
                          waitingForTap = false;
                          currentQrData = null;
                          qrPosition = null;
                          qrPageNumber = null;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('QR berhasil disimpan ke PDF!'),
                            duration: Duration(seconds: 2),
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
            if (waitingForTap || qrLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Selesaikan penempatan QR sebelumnya atau tunggu.',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }

            final result = await showInputDialog(
              context: context,
              formKey: _formKey,
              nipController: nipController,
              tujuanController: tujuanController,
              showTujuan: true,
              totalPages: pdfViewerController.pageCount, // Add this line
            );

            if (result != null && result['encrypted_link'] != null) {
              setState(() {
                currentQrData = result['encrypted_link'];
                waitingForTap = true;
                qrLocked = false;
                qrPosition = null;
                qrPageNumber = null;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Silakan tap di PDF untuk menempatkan QR Code. Anda bisa menggesernya.',
                  ),
                  duration: Duration(seconds: 4),
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
    // Membaca file PDF yang ada
    final fileBytes = await File(widget.filePath).readAsBytes();
    // Objek PdfDocument dibuat di sini, lokal untuk fungsi ini.
    // Ini adalah langkah kunci untuk mengatasi error "undefined_getter"
    final PdfDocument document = PdfDocument(inputBytes: fileBytes);

    final QrPainter qrPainter = QrPainter.withQr(
      qr: QrValidator.validate(
        data:
            'http://fakerryugan.my.id/api/signature/view-from-payload?payload=$data',
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      ).qrCode!,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );

    final ui.Image qrImage = await qrPainter.toImage(qrPdfSize * 3);

    final ByteData? byteData = await qrImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw Exception('Failed to convert QR image to bytes.');
    }
    final Uint8List bytes = byteData.buffer.asUint8List();
    final PdfBitmap pdfImage = PdfBitmap(bytes);

    final int pageIndex = page - 1;
    if (pageIndex < 0 || pageIndex >= document.pages.count) {
      throw Exception('Invalid page number: $page');
    }
    final PdfPage pdfPage = document.pages[pageIndex];

    final RenderBox pdfViewerRenderBox =
        _pdfViewerKey.currentContext!.findRenderObject() as RenderBox;
    final Size pdfViewerScreenSize = pdfViewerRenderBox.size;

    final Size pdfPageActualSize = pdfPage.size;

    final double zoomLevel = pdfViewerController.zoomLevel;
    final Offset scrollOffset = pdfViewerController.scrollOffset;

    final double scaleX =
        pdfPageActualSize.width / (pdfViewerScreenSize.width * zoomLevel);
    final double scaleY =
        pdfPageActualSize.height / (pdfViewerScreenSize.height * zoomLevel);

    final double pdfX = (offset.dx + scrollOffset.dx) * scaleX;
    final double pdfYFromTop = (offset.dy + scrollOffset.dy) * scaleY;

    // Completed the line that was cut off previously
    final double finalPdfY = pdfPageActualSize.height - pdfYFromTop - qrPdfSize;

    // Gambar QR code ke halaman PDF
    pdfPage.graphics.drawImage(
      pdfImage,
      Rect.fromLTWH(pdfX, finalPdfY, qrPdfSize, qrPdfSize),
    );

    // Simpan PDF yang sudah dimodifikasi
    final String outputPath =
        '${widget.filePath.substring(0, widget.filePath.lastIndexOf('.'))}_signed.pdf';
    final File newFile = File(outputPath);
    await newFile.writeAsBytes(await document.save());
    document.dispose();

    // Navigasi untuk memuat ulang PDF yang sudah ditandatangani
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PdfViewerPage(filePath: outputPath)),
    );
  }
}
