import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdfViewerPage extends StatefulWidget {
  final Uint8List pdfBytes;
  final String baseUrl;
  final Map<String, dynamic> qr; // expects at least {'sign_token': '...'}

  const PdfViewerPage({
    Key? key,
    required this.pdfBytes,
    required this.baseUrl,
    required this.qr,
  }) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  double qrX = 100;
  double qrY = 500;
  double qrSize = 150;

  @override
  void initState() {
    super.initState();
    _loadQrPrefs();
  }

  Future<void> _loadQrPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      qrX = prefs.getDouble('qrX') ?? 100;
      qrY = prefs.getDouble('qrY') ?? 500;
      qrSize = prefs.getDouble('qrSize') ?? 150;
    });
  }

  Future<void> _saveQrPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('qrX', qrX);
    await prefs.setDouble('qrY', qrY);
    await prefs.setDouble('qrSize', qrSize);
  }

  /// Membuat PDF baru dengan QR di posisi & ukuran yang dipilih user
  Future<Uint8List> _generatePdfWithQr() async {
    final PdfDocument document = PdfDocument(inputBytes: widget.pdfBytes);

    try {
      final PdfPage page = document.pages[0];

      // Validasi QR
      final validation = QrValidator.validate(
        data: "${widget.baseUrl}/view/${widget.qr['sign_token']}",
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );
      if (validation.qrCode == null) {
        throw Exception("Data QR tidak valid");
      }

      final qrPainter = QrPainter.withQr(
        qr: validation.qrCode!,
        gapless: true,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );

      // Render ke gambar
      int imgSizePx = qrSize.toInt().clamp(16, 2000);
      final ui.Image qrImage = await qrPainter.toImage(imgSizePx.toDouble());

      final ByteData? byteData =
      await qrImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Gagal membuat gambar QR");

      final Uint8List bytes = byteData.buffer.asUint8List();
      final PdfBitmap pdfImage = PdfBitmap(bytes);

      // Ukuran halaman PDF
      final double pageW = page.size.width;
      final double pageH = page.size.height;

      // Konversi koordinat Flutter (top-left) ke koordinat PDF (bottom-left)
      final double drawSize = qrSize.clamp(16.0, math.min(pageW, pageH));
      final double drawX = qrX.clamp(0.0, pageW - drawSize);
      final double drawY =
      (pageH - qrY - drawSize).clamp(0.0, pageH - drawSize);

      page.graphics.drawImage(
        pdfImage,
        Rect.fromLTWH(drawX, drawY, drawSize, drawSize),
      );

      // Simpan PDF baru
      final List<int> listBytes = await document.save();
      return Uint8List.fromList(listBytes);
    } finally {
      document.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF dengan QR"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              try {
                final newPdfBytes = await _generatePdfWithQr();
                await _saveQrPrefs();

                // TODO: simpan newPdfBytes ke file atau upload ke server

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("QR berhasil disimpan ke PDF")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // PDF viewer
          SfPdfViewer.memory(widget.pdfBytes),

          // Overlay QR
          Positioned(
            left: qrX,
            top: qrY,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  qrX += details.delta.dx;
                  qrY += details.delta.dy;
                });
              },
              onScaleUpdate: (details) {
                if (details.scale != 1.0) {
                  setState(() {
                    qrSize = (qrSize * details.scale).clamp(16.0, 800.0);
                  });
                }
              },
              child: Container(
                width: qrSize,
                height: qrSize,
                color: Colors.transparent,
                child: QrImageView(
                  data: "${widget.baseUrl}/view/${widget.qr['sign_token']}",
                  size: qrSize,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () async {
          await _saveQrPrefs();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Posisi QR disimpan (lokal)")),
          );
        },
      ),
    );
  }
}
