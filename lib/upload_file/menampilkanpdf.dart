import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'
    show PdfPageInfo; // <--- TAMBAHKAN ATAU PASTIKAN INI ADA
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
  Offset? qrPosition;
  int? qrPageNumber;
  bool waitingForTap = false;
  bool qrLocked =
      false;
  static const double qrDisplaySize = 100.0; // Ukuran QR di UI (untuk drag)
  static const double qrPdfSize =
      100.0;

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

                        final SfPdfViewerState? viewerState =
                            _pdfViewerKey.currentState;
                        if (viewerState == null ||
                            qrPosition == null ||
                            qrPageNumber == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error: Posisi QR tidak valid.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        final PdfPageInfo
                        pageInfo = viewerState.convertPointToPageInfo(
                          Offset(
                            qrPosition!.dx +
                                (qrDisplaySize / 2), // Titik tengah QR di layar
                            qrPosition!.dy +
                                (qrDisplaySize / 2), // Titik tengah QR di layar
                          ),
                          qrPageNumber!,
                        );
                        final Offset pdfPointOffset = Offset(
                          pageInfo.bounds.left,
                          pageInfo.bounds.top,
                        );

                        await insertQrToPdfDirectly(
                          data: currentQrData!,
                          page:
                              pageInfo.pageIndex +
                              1,
                          offset:
                              pdfPointOffset, // Gunakan offset yang sudah dikonversi
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
              totalPages: pdfViewerController.pageCount,
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
    required int page, // Ini adalah 1-indexed
    required Offset offset, // Ini sudah dalam koordinat PDF (points)
  }) async {
    // Membaca file PDF yang ada
    final fileBytes = await File(widget.filePath).readAsBytes();
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

    // Page index untuk Syncfusion adalah 0-indexed
    final int pageIndex = page - 1;
    if (pageIndex < 0 || pageIndex >= document.pages.count) {
      throw Exception('Invalid page number: $page');
    }
    final PdfPage pdfPage = document.pages[pageIndex];

    // pdfPageActualSize adalah ukuran halaman PDF dalam points (standar 72 DPI)
    final Size pdfPageActualSize = pdfPage.size;

    // offset.dx dan offset.dy sekarang sudah dalam koordinat PDF (points)
    // dan relatif terhadap pojok kiri atas halaman PDF.
    // Namun, Syncfusion PDF memiliki koordinat Y yang dimulai dari bawah.
    // Jadi, kita perlu mengonversi Y dari top-origin ke bottom-origin.

    final double finalPdfX = offset.dx; // X sudah benar
    // Koordinat Y di PDF dimulai dari bawah.
    // offset.dy adalah jarak dari atas.
    // pdfPageActualSize.height adalah tinggi halaman PDF.
    // qrPdfSize adalah tinggi QR dalam points.
    // Jadi, (pdfPageActualSize.height - offset.dy) adalah Y dari bawah
    // dikurangi tinggi QR agar posisi QR pas di atas offset.dy.
    final double finalPdfY = pdfPageActualSize.height - offset.dy - qrPdfSize;

    // Gambar QR code ke halaman PDF
    pdfPage.graphics.drawImage(
      pdfImage,
      Rect.fromLTWH(finalPdfX, finalPdfY, qrPdfSize, qrPdfSize),
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
