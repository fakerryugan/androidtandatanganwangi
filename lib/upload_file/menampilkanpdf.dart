import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

import '../api/token.dart';
import 'package:android/upload_file/generateqr.dart';
import 'package:android/upload_file/resizeqr.dart';
import 'package:android/bottom_navbar/bottom_navbar.dart';

/// Global ScaffoldMessenger untuk notifikasi
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final int documentId;
  final Map<String, dynamic>? qrData;

  const PdfViewerPage({
    Key? key,
    required this.filePath,
    required this.documentId,
    this.qrData,
  }) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final TextEditingController nipController = TextEditingController();
  final TextEditingController tujuanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final GlobalKey<SfPdfViewerState> _pdfViewerKey =
  GlobalKey<SfPdfViewerState>();

  List<Map<String, dynamic>> qrCodes = [];
  bool _isProcessing = false;
  bool _isSending = false;
  late String _currentPdfPath;

  // ✅ ukuran default QR
  static const double _initialQrSize = 100.0;

  @override
  void initState() {
    super.initState();
    _currentPdfPath = widget.filePath;

    if (widget.qrData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final viewSize = MediaQuery.of(context).size;
        setState(() {
          qrCodes.add({
            ...widget.qrData!,
            'position': Offset(
              viewSize.width / 2 - _initialQrSize / 2,
              viewSize.height / 2 - _initialQrSize / 2,
            ),
            'size': _initialQrSize,
            'locked': true,
          });
        });
      });
    }
  }

  // =====================================================
  // Generate QR → Uint8List
  // =====================================================
  Future<Uint8List> _generateQrCodeBytes(String data,
      {double size = 100.0}) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      color: Colors.black,
      emptyColor: Colors.white,
    );
    final uiImage = await painter.toImage(size);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // =====================================================
  // Simpan QR ke PDF
  // =====================================================
  Future<void> _saveAllQrCodesToPdf(dynamic pdfViewerController) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final scaffold = scaffoldMessengerKey.currentState;
      scaffold?.showSnackBar(
        const SnackBar(content: Text('Menyimpan QR ke PDF...')),
      );

      final originalFileBytes = await File(widget.filePath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: originalFileBytes);

      final qrCodesToSave = qrCodes.where((q) => q['locked'] != true).toList();

      if (qrCodesToSave.isEmpty) {
        scaffold?.showSnackBar(
          const SnackBar(content: Text('Tidak ada QR yang perlu disimpan')),
        );
        return;
      }

      // for (final qr in unlockedQrs) {
      //   // ✅ Ambil ukuran QR sesuai drag-resize (fallback ke _initialQrSize)
      //   final double qrSize = (qr['size'] ?? _initialQrSize).toDouble();
      //
      //   final qrPainter = QrPainter.withQr(
      //     qr: QrValidator.validate(
      //       data: "$baseUrl/view/${qr['sign_token']}",
      //       version: QrVersions.auto,
      //       errorCorrectionLevel: QrErrorCorrectLevel.H,
      //     ).qrCode!,
      //     gapless: true,
      //     color: const Color(0xFF000000),
      //     emptyColor: const Color(0xFFFFFFFF), // background putih biar kontras
      //   );
      //
      //   // ✅ Render QR dengan resolusi tinggi (×4 dari ukuran asli)
      //   final ui.Image qrImage = await qrPainter.toImage((qrSize * 4));
      //   final ByteData? byteData =
      //   await qrImage.toByteData(format: ui.ImageByteFormat.png);
      //   if (byteData == null) continue;
      //
      //   final Uint8List bytes = byteData.buffer.asUint8List();
      //   final PdfBitmap pdfImage = PdfBitmap(bytes);
      //
      //   final int pageIndex = (qr['selected_page'] ?? 1) - 1;
      //   if (pageIndex < 0 || pageIndex >= document.pages.count) continue;
      //
      //   final PdfPage pdfPage = document.pages[pageIndex];
      //   final Offset position = qr['position'] ?? Offset.zero;
      //
      //   // ✅ Ambil ukuran halaman PDF & ukuran viewer
      //   final Size pageSize = pdfPage.size;
      //   final Size viewSize = _pdfViewerKey.currentContext?.size ?? Size.zero;
      //   final double zoomLevel = pdfViewerController.zoomLevel;
      //
      //   // ✅ Hitung scaling (anggap proporsional, pakai scaleX saja)
      //   final double scaleX = pageSize.width / (viewSize.width * zoomLevel);
      //   final double scaleY = pageSize.height / (viewSize.height * zoomLevel);
      //
      //   // ✅ Mapping ke koordinat PDF
      //   // var pdfX = position.dx * scaleX;
      //   // var qrSizeInPdf = qrSize * scaleX;
      //   // var pdfY = pageSize.height - (position.dy * scaleY) - qrSizeInPdf;


      for (final qr in qrCodesToSave) {
        if (qr['locked'] == false) {
          final int pageIndex = (qr['selected_page'] as int) - 1;
          final PdfPage pdfPage = document.pages[pageIndex];
          final Offset position = qr['position'] as Offset;
          final double qrSize = qr['size'] as double;
          final String signToken = qr['sign_token'] as String;

          final imageBytes = await QrPainter(
            data: signToken,
            version: QrVersions.auto,
            gapless: true,
          ).toImageData(1024); // Ukuran gambar resolusi tinggi


          if (imageBytes != null) {
            final pdfImage = PdfBitmap(imageBytes.buffer.asUint8List());
            final Size pageSize = pdfPage.size;
            final Size viewSize = _pdfViewerKey.currentContext?.size ?? Size.zero;

            // ========================================================
            // ✅ PERBAIKAN FINAL (REVISI): Kembali ke Logika Intuitif
            // ========================================================


            final Offset scrollOffset = _pdfViewerController.scrollOffset;

// 2. Hitung padding internal (letterboxing/pillarboxing) yang diterapkan oleh SfPdfViewer.
            final double viewAspectRatio = viewSize.width / viewSize.height;
            final double pageAspectRatio = pageSize.width / pageSize.height;
            double internalPaddingX = 0;
            double internalPaddingY = 0;
            double effectiveViewWidth;

            if (pageAspectRatio > viewAspectRatio) {
              // Pillarbox (padding atas/bawah)
              effectiveViewWidth = viewSize.width;
              final double effectiveViewHeight = effectiveViewWidth / pageAspectRatio;
              internalPaddingY = (viewSize.height - effectiveViewHeight) / 2;
            } else {
              // Letterbox (padding kiri/kanan)
              final double effectiveViewHeight = viewSize.height;
              effectiveViewWidth = effectiveViewHeight * pageAspectRatio;
              internalPaddingX = (viewSize.width - effectiveViewWidth) / 2;
            }

// 3. Hitung skala yang benar berdasarkan lebar efektif PDF yang terlihat.
            final double scale = pageSize.width / effectiveViewWidth;

// 4. Hitung posisi PUSAT QR di layar.
            final Offset qrCenterOnScreen = Offset(
              position.dx + (qrSize / 2),
              position.dy + (qrSize / 2),
            );

// 5. Hitung posisi mentah (raw position) dari PUSAT QR,
//    DENGAN MENGURANGI PADDING INTERNAL untuk mendapatkan posisi yang benar
//    relatif terhadap PDF yang terlihat.
            final double rawCenterX = (qrCenterOnScreen.dx - internalPaddingX) + scrollOffset.dx;
            final double rawCenterY = (qrCenterOnScreen.dy - internalPaddingY) + scrollOffset.dy;

// 6. Konversi posisi PUSAT dan ukuran ke unit PDF menggunakan skala yang akurat.
            double pdfCenterX = rawCenterX * scale;
            double qrSizeInPdf = qrSize * scale;

// 7. Konversi sumbu Y untuk PUSAT QR.
            double pdfCenterY = pageSize.height - (rawCenterY * scale);

// 8. Hitung posisi pojok kiri-atas (x, y) dari pusat QR di koordinat PDF.
            double pdfX = pdfCenterX - (qrSizeInPdf / 2);
            double pdfY = pdfCenterY - (qrSizeInPdf / 2);

// 9. Clamp (batasi) nilai agar tidak keluar dari halaman.
            pdfX = pdfX.clamp(0, pageSize.width - qrSizeInPdf);
            pdfY = pdfY.clamp(0, pageSize.height - qrSizeInPdf);

// Debug log untuk verifikasi
            debugPrint("=== QR Mapping (PADDING CORRECTED) ===");
            debugPrint("Internal Padding: x=${internalPaddingX.toStringAsFixed(2)}, y=${internalPaddingY.toStringAsFixed(2)}");
            debugPrint("Scale (Corrected): ${scale.toStringAsFixed(4)}");
            debugPrint("Final PDF Top-Left: x=${pdfX.toStringAsFixed(2)}, y=${pdfY.toStringAsFixed(2)}, size=${qrSizeInPdf.toStringAsFixed(2)}");
            debugPrint("======================================");

// Gambar QR ke PDF menggunakan koordinat pojok kiri-atas yang sudah benar.
            pdfPage.graphics.drawImage(
              pdfImage,
              Rect.fromLTWH(pdfX, pdfY, qrSizeInPdf, qrSizeInPdf),
            );
            // ========================================================
            // ✅ AKHIR DARI BLOK PERBAIKAN
            // ========================================================
          }
        }
      }

        final tempPath =
            '${Directory.systemTemp.path}/temp_${DateTime
            .now()
            .millisecondsSinceEpoch}.pdf';
        await File(tempPath).writeAsBytes(await document.save());
        document.dispose();

        await File(_currentPdfPath).delete();
        await File(tempPath).rename(_currentPdfPath);

        setState(() {
          qrCodes = qrCodes.map((qr) => {...qr, 'locked': true}).toList();
        });

        scaffold?.showSnackBar(
          const SnackBar(content: Text('QR berhasil disimpan!')),
        );
      } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }


  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final unlockedQr = qrCodes.where((q) => q['locked'] == false).toList();
    final bool hasUnlockedQr = unlockedQr.isNotEmpty;

    return Scaffold(
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              GestureDetector(
                onTapDown: (details) {
                  if (hasUnlockedQr) {
                    final qrToMove = unlockedQr.first;
                    final newPosition = details.localPosition -
                        Offset(qrToMove['size'] / 2, qrToMove['size'] / 2);
                    setState(() {
                      final index = qrCodes.indexWhere(
                              (q) => q['sign_token'] == qrToMove['sign_token']);
                      if (index != -1) {
                        qrCodes[index]['position'] = Offset(
                          newPosition.dx.clamp(
                              0, constraints.maxWidth - qrToMove['size']),
                          newPosition.dy.clamp(
                              0, constraints.maxHeight - qrToMove['size']),
                        );
                        qrCodes[index]['selected_page'] =
                            _pdfViewerController.pageNumber;
                      }
                    });
                  }
                },
                child: SfPdfViewer.file(
                  File(_currentPdfPath),
                  key: _pdfViewerKey,
                  controller: _pdfViewerController,
                ),
              ),
              ...unlockedQr.map((qr) {
                final index = qrCodes
                    .indexWhere((q) => q['sign_token'] == qr['sign_token']);
                return ResizableQrCode(
                  key: ValueKey(qr['sign_token']),
                  constraints: constraints,
                  qrData: qr,
                  onDragUpdate: (newPosition) {
                    qrCodes[index]['position'] = newPosition;
                  },
                  onResizeUpdate: (newSize) {
                    qrCodes[index]['size'] = newSize;
                  },
                  onDragEnd: () {
                    setState(() {
                      qrCodes[index]['selected_page'] =
                          _pdfViewerController.pageNumber;
                    });
                  },
                );
              }).toList(),
              _buildBottomNavigation(hasUnlockedQr),
              if (_isProcessing) const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
      floatingActionButton: Visibility(
        visible: !_isProcessing && (!_isSending),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 70.0),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.white,
            onPressed: () async {
              if (qrCodes.where((q) => q['locked'] == false).isNotEmpty) {
                // PANGGIL FUNGSI DENGAN TANDA KURUNG DAN ARGUMEN
                await _saveAllQrCodesToPdf(_pdfViewerController);
                // `setState` setelahnya tidak lagi diperlukan di sini,
                // karena sudah diatur di dalam _saveAllQrCodesToPdf
              } else {
                _addNewQrCode();
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            label: Text(
              hasUnlockedQr ? 'Simpan Posisi QR' : '+ Tanda Tangan',
              style: const TextStyle(color: Colors.black),
            ),
            icon: Icon(
              hasUnlockedQr ? Icons.save : Icons.edit,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Edit & Tanda Tangan',
          style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF172B4C),
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildBottomNavigation(bool hasUnlockedQr) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: Container(
          height: 60,
          color: const Color(0xFF172B4C),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBackButton(),
              if (!hasUnlockedQr && qrCodes.isNotEmpty) _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_outlined, color: Color(0xFF172B4C)),
        onPressed: _showCancelConfirmationDialog,
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(15),
      ),
      child: _isSending
          ? const Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(color: Colors.white),
      )
          : IconButton(
        icon: const Icon(Icons.send, color: Colors.white),
        onPressed: _sendDocument,
      ),
    );
  }

  // =====================================================
  // Tambah QR
  // =====================================================
  void _addNewQrCode() async {
    final result = await showInputDialog(
      context: context,
      formKey: _formKey,
      nipController: nipController,
      tujuanController: tujuanController,
      showTujuan: true,
      totalPages: _pdfViewerController.pageCount,
      documentId: widget.documentId,
    );
    if (result != null && result['sign_token'] != null) {
      final viewSize = MediaQuery.of(context).size;
      setState(() {
        qrCodes.add({
          'sign_token': result['sign_token'],
          'selected_page': result['selected_page'],
          'position': Offset(
            viewSize.width / 2 - _initialQrSize / 2,
            viewSize.height / 2 - _initialQrSize / 2,
          ),
          'size': _initialQrSize,
          'locked': false,
        });
      });
    }
  }

  // =====================================================
  // Kirim dokumen
  // =====================================================
  Future<void> _sendDocument() async {
    try {
      setState(() => _isSending = true);
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      if (authToken == null) throw Exception('Token tidak valid');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/documents/replace/${widget.documentId}'),
      );
      request.headers['Authorization'] = 'Bearer $authToken';
      request.files.add(
        await http.MultipartFile.fromPath(
          'pdf', // ✅ tanpa spasi
          _currentPdfPath,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Dokumen berhasil dikirim!')),
        );
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
                (route) => false,
          );
        }
      } else {
        throw Exception(
          jsonDecode(responseBody)['message'] ?? 'Gagal mengirim dokumen',
        );
      }
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // =====================================================
  // Batalkan dokumen
  // =====================================================
  Future<void> _showCancelConfirmationDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Dokumen'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan dokumen ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: _isProcessing
                ? null
                : () async {
              Navigator.of(context).pop();
              await _cancelDocumentRequest();
            },
            child: _isProcessing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelDocumentRequest() async {
    try {
      setState(() => _isProcessing = true);
      final response = await cancelDocument(widget.documentId);

      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('document_id');

        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Dokumen dibatalkan')),
        );
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
                (route) => false,
          );
        }
      } else {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal membatalkan')),
        );
      }
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
