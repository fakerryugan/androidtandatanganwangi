import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui; // Alias 'ui' untuk dart:ui
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Untuk menampilkan QR di Flutter UI
import 'package:qr/qr.dart'; // Untuk membuat data QR (QrCode)
// Untuk mendapatkan direktori penyimpanan
// Untuk membuka file PDF

// Pastikan ini adalah file Anda yang berisi showInputDialog
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
  bool waitingForTap = false; // Menunggu pengguna tap untuk menempatkan QR
  bool qrLocked =
      false; // Menandakan QR sudah ditempatkan dan siap disimpan permanen

  // Ukuran QR code di layar dan di PDF
  static const double qrDisplaySize = 100.0; // Ukuran QR di UI (untuk drag)
  static const double qrPdfSize = 100.0; // Ukuran QR saat disisipkan ke PDF

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
        // Hapus `leading: const SizedBox()` jika Anda ingin tombol back default
        // Jika Anda ingin tombol back kustom atau tidak ada, biarkan seperti ini
      ),
      body: Stack(
        children: [
          // PDF Viewer
          GestureDetector(
            // Menonaktifkan interaksi PDF saat menunggu tap
            onTapDown: waitingForTap && !qrLocked
                ? (details) {
                    // Mendapatkan RenderBox dari viewer untuk mengkonversi posisi global ke lokal
                    final RenderBox renderBox =
                        _pdfViewerKey.currentContext!.findRenderObject()
                            as RenderBox;
                    final Offset localPosition = renderBox.globalToLocal(
                      details.globalPosition,
                    );

                    setState(() {
                      // Simpan posisi relatif terhadap bagian dalam viewer
                      qrPosition = localPosition;
                    });
                  }
                : null, // Nonaktifkan GestureDetector jika tidak menunggu tap
            child: SfPdfViewer.file(
              file,
              key: _pdfViewerKey,
              controller: pdfViewerController,
              // Jika Anda ingin menonaktifkan interaksi PDF lainnya saat menunggu tap
              canShowHyperlinkDialog: !waitingForTap,
              canShowPasswordDialog: !waitingForTap,
              canShowPaginationDialog: !waitingForTap,
              canShowScrollHead: !waitingForTap,
              // Tambahkan lebih banyak properti jika perlu untuk menonaktifkan interaksi
            ),
          ),

          // QR Code yang bisa di-drag
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
                    // Container untuk memastikan area sentuh dan background putih QR
                    Container(
                      width: qrDisplaySize,
                      height: qrDisplaySize,
                      color: Colors.white, // Background putih untuk QR
                      child: QrImageView(
                        data:
                            "http://fakerryugan.my.id/api/signature/view-from-payload?payload=$currentQrData",
                        version: QrVersions.auto,
                        size: qrDisplaySize, // Pastikan ukuran sesuai
                      ),
                    ),
                    // Tombol kunci/simpan QR
                    if (!qrLocked)
                      IconButton(
                        icon: const Icon(
                          Icons.lock,
                          color: Colors.black,
                          size: 24,
                        ),
                        onPressed: () async {
                          // Tampilkan loading saat proses penyimpanan
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Menyimpan QR ke PDF...'),
                            ),
                          );

                          // Panggil fungsi untuk menyisipkan QR ke PDF
                          await insertQrToPdfDirectly(
                            data: currentQrData!,
                            // Gunakan pageNumber dari controller
                            page: pdfViewerController.pageNumber,
                            offset: qrPosition!,
                          );

                          // Reset state setelah QR berhasil disimpan
                          setState(() {
                            qrLocked =
                                true; // Status terkunci menjadi true setelah disimpan
                            waitingForTap = false;
                            currentQrData = null; // Hapus data QR sementara
                            qrPosition = null; // Hapus posisi QR di layar
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('QR berhasil disimpan ke PDF!'),
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
            // Jika sedang menunggu tap atau QR sudah terkunci, jangan biarkan membuat QR baru
            if (waitingForTap || qrLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Selesaikan penempatan QR sebelumnya atau tunggu.',
                  ),
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
                waitingForTap = true; // Set status menunggu tap
                qrLocked = false; // Pastikan belum terkunci
                qrPosition = null; // Reset posisi QR
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Silakan tap di PDF untuk menempatkan QR Code. Anda bisa menggesernya.',
                  ),
                  duration: Duration(
                    seconds: 4,
                  ), // Durasi lebih lama agar terbaca
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
    required Offset offset, // Offset ini adalah posisi di layar (widget)
  }) async {
    // Membaca file PDF yang ada
    final fileBytes = await File(widget.filePath).readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: fileBytes);

    // Membuat QR Code sebagai gambar PNG
    final QrPainter qrPainter = QrPainter.withQr(
      qr: QrValidator.validate(
        data:
            'http://fakerryugan.my.id/api/signature/view-from-payload?payload=$data',
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      ).qrCode!,
      gapless: true,
      color: const Color(0xFF000000), // Warna QR hitam
      emptyColor: const Color(0xFFFFFFFF), // Warna background QR putih
    );

    // Menggambar QR ke ui.Image dengan ukuran yang diinginkan untuk PDF
    // Pastikan ukuran ini cukup besar untuk kualitas yang baik
    final ui.Image qrImage = await qrPainter.toImage(qrPdfSize);

    // Mengkonversi ui.Image ke Uint8List (PNG bytes)
    final ByteData? byteData = await qrImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    if (byteData == null) {
      throw Exception('Gagal mengkonversi QR image ke bytes.');
    }
    final Uint8List bytes = byteData.buffer.asUint8List();
    final PdfBitmap pdfImage = PdfBitmap(bytes); // Membuat PdfBitmap dari bytes

    // Dapatkan halaman PDF yang akan dimodifikasi
    final int pageIndex = page - 1; // PdfDocument menggunakan 0-indexed pages
    if (pageIndex < 0 || pageIndex >= document.pages.count) {
      throw Exception('Nomor halaman tidak valid: $page');
    }
    final PdfPage pdfPage = document.pages[pageIndex];

    // --- Perhitungan Posisi QR di Halaman PDF ---
    // Konversi koordinat layar (offset) ke koordinat PDF
    // 1. Dapatkan RenderBox dari SfPdfViewer
    final RenderBox pdfViewerRenderBox =
        _pdfViewerKey.currentContext!.findRenderObject() as RenderBox;
    final Size pdfViewerSize =
        pdfViewerRenderBox.size; // Ukuran viewer di layar

    // 2. Dapatkan ukuran halaman PDF sebenarnya
    final Size pdfPageSize = pdfPage.size;

    // 3. Dapatkan zoom level dan scroll offset dari controller
    final double zoomLevel = pdfViewerController.zoomLevel;
    final Offset scrollOffset = pdfViewerController.scrollOffset;

    // Hitung posisi horizontal (X)
    // Offset.dx adalah posisi tap dari kiri viewer
    // dx di PDF adalah posisi tap relatif terhadap lebar halaman PDF sebenarnya
    final double pdfX =
        (offset.dx + scrollOffset.dx) /
        (pdfViewerSize.width * zoomLevel) *
        pdfPageSize.width;

    // Hitung posisi vertikal (Y)
    // Offset.dy adalah posisi tap dari atas viewer
    // Karena PDF memiliki origin di kiri-bawah, kita perlu mengkoreksi Y
    // dy di PDF adalah posisi tap relatif terhadap tinggi halaman PDF sebenarnya
    final double pdfY =
        (offset.dy + scrollOffset.dy) /
        (pdfViewerSize.height * zoomLevel) *
        pdfPageSize.height;

    // Koreksi untuk origin PDF (biasanya kiri-bawah)
    // Posisi Y di PDF dihitung dari bawah. Jadi, jika kita ingin meletakkan
    // gambar di (pdfX, pdfY) dari atas, kita perlu mengurangi tinggi halaman PDF
    // dikurangi posisi Y yang dihitung, lalu kurangi tinggi gambar QR.
    final double correctedPdfY = pdfPageSize.height - pdfY - qrPdfSize;

    // Gambar QR code ke halaman PDF
    pdfPage.graphics.drawImage(
      pdfImage,
      Rect.fromLTWH(pdfX, correctedPdfY, qrPdfSize, qrPdfSize),
    );

    // Simpan PDF yang sudah dimodifikasi
    final String outputPath =
        '${widget.filePath.substring(0, widget.filePath.lastIndexOf('.'))}_signed.pdf';
    final File newFile = File(outputPath);
    await newFile.writeAsBytes(await document.save());
    document.dispose(); // Pastikan dokumen dibuang setelah selesai

    // Navigasi ke halaman viewer baru dengan PDF yang sudah ditandatangani
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PdfViewerPage(filePath: outputPath)),
    );
  }
}
