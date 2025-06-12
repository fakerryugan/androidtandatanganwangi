import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui; // Alias 'ui' untuk dart:ui

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Untuk menampilkan QR di Flutter UI
// Untuk membuat data QR (QrCode)

// import 'package:open_filex/open_filex.dart'; // Opsional: Untuk membuka file PDF

// Pastikan ini adalah file Anda yang berisi showInputDialog
import 'package:android/upload_file/generateqr.dart'; // Sesuaikan path ini

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
          // PDF Viewer dengan GestureDetector untuk menangkap tap
          GestureDetector(
            onTapDown: waitingForTap && !qrLocked
                ? (details) {
                    setState(() {
                      // Simpan posisi tap di layar (relatif terhadap GestureDetector)
                      qrPosition = details.localPosition;
                      qrPageNumber = pdfViewerController
                          .pageNumber; // Ambil halaman saat ini
                      waitingForTap =
                          false; // Setelah tap, tidak lagi menunggu tap
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

          // QR Code yang bisa di-drag
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
                      color: Colors.white, // Background putih untuk QR
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
    required int page, // Nomor halaman (1-indexed) tempat QR akan ditempatkan
    required Offset offset, // Offset ini adalah posisi di layar (widget)
  }) async {
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

    // Render QR ke ui.Image dengan resolusi tinggi
    final ui.Image qrImage = await qrPainter.toImage(
      qrPdfSize * 3,
    ); // Faktor 3 untuk resolusi lebih baik

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

    // --- Perhitungan Posisi QR di Halaman PDF ---
    // Dapatkan RenderBox dari SfPdfViewer untuk mendapatkan ukuran dan posisi di layar
    final RenderBox pdfViewerRenderBox =
        _pdfViewerKey.currentContext!.findRenderObject() as RenderBox;
    final Size pdfViewerScreenSize =
        pdfViewerRenderBox.size; // Ukuran viewer di layar (piksel)

    // Dapatkan ukuran halaman PDF sebenarnya (dalam points)
    final Size pdfPageActualSize =
        pdfPage.size; // Ukuran halaman PDF dalam points

    // Dapatkan zoom level dari controller
    final double zoomLevel = pdfViewerController.zoomLevel;

    // Dapatkan posisi scroll halaman dalam PDF viewer
    // Ini penting karena offset.dx/dy adalah relatif terhadap viewer,
    // bukan halaman PDF yang sedang digulir.
    final Offset scrollOffset = pdfViewerController.scrollOffset;

    // Posisi QR di layar (offset) adalah relatif terhadap SfPdfViewer.
    // Kita perlu menghitung posisi ini relatif terhadap *halaman PDF yang terlihat*
    // di dalam viewer, lalu mengkonversinya ke koordinat PDF.

    // Calculate the scale factor from screen pixels to PDF points
    // This is the true scale of the PDF page being displayed on screen
    final double scaleX =
        pdfPageActualSize.width / (pdfViewerScreenSize.width * zoomLevel);
    final double scaleY =
        pdfPageActualSize.height / (pdfViewerScreenSize.height * zoomLevel);

    // Menghitung posisi QR di halaman PDF (dalam points)
    // Offset.dx/dy adalah posisi tap di dalam RenderBox (pixels).
    // Kita perlu mengkoreksi ini dengan scrollOffset untuk mendapatkan posisi relatif
    // terhadap bagian atas/kiri halaman PDF di dalam koordinat viewer.
    // Kemudian, konversi ke PDF points.

    // Hitung posisi X dan Y di PDF (dari kiri atas halaman PDF)
    // `offset.dx` adalah posisi tap dari kiri viewer.
    // `scrollOffset.dx` adalah seberapa jauh konten PDF digulir ke kanan (viewport bergerak ke kiri).
    // Jadi, untuk mendapatkan posisi yang *sesungguhnya* di halaman PDF, kita tambahkan scrollOffset.
    final double pdfX = (offset.dx + scrollOffset.dx) * scaleX;

    // Untuk Y, serupa: tambahkan scrollOffset.dy
    final double pdfYFromTop = (offset.dy + scrollOffset.dy) * scaleY;

    // Koordinat Y di PDF (Syncfusion PDF) dihitung dari bawah halaman.
    // Kita memiliki `pdfYFromTop` yang dihitung dari atas halaman.
    // Konversi `pdfYFromTop` ke Y dari bawah:
    // `pdfPageActualSize.height` adalah tinggi total halaman PDF.
    // `qrPdfSize` adalah tinggi QR code itu sendiri (dalam points).
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
