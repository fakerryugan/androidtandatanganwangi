import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:android/upload_file/generateqr.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/token.dart';
import 'package:android/bottom_navbar/bottom_navbar.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();

// Add this extension for Offset clamping
extension OffsetClamp on Offset {
  Offset clamp(Offset min, Offset max) {
    return Offset(dx.clamp(min.dx, max.dx), dy.clamp(min.dy, max.dy));
  }
}

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final int documentId;
  final Map<String, dynamic>? qrData;

  static const double qrDisplaySize = 100.0;
  static const double qrPdfSize = 100.0;

  const PdfViewerPage({
    Key? key,
    required this.filePath,
    required this.documentId,
    this.qrData,
  }) : super(key: key);

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final TextEditingController nipController = TextEditingController();
  final TextEditingController tujuanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> qrCodes = [];
  bool _isProcessing = false;
  bool _isSending = false;
  late String _currentPdfPath;

  @override
  void initState() {
    super.initState();
    _currentPdfPath = widget.filePath;
    if (widget.qrData != null) {
      qrCodes.add({
        ...widget.qrData!,
        'position': Offset(
          MediaQuery.of(context).size.width / 2 -
              PdfViewerPage.qrDisplaySize / 2,
          MediaQuery.of(context).size.height / 2 -
              PdfViewerPage.qrDisplaySize / 2,
        ),
        'locked': true,
      });
    }
  }

  bool _isValidPosition(Offset position, Size pdfViewerSize) {
    return position.dx >= 0 &&
        position.dy >= 0 &&
        position.dx <= pdfViewerSize.width - PdfViewerPage.qrDisplaySize &&
        position.dy <= pdfViewerSize.height - PdfViewerPage.qrDisplaySize;
  }

  Widget _buildBottomNavigation() {
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
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBackButton(),
                if (qrCodes.isNotEmpty && qrCodes.any((q) => q['locked']))
                  _buildSendButton(),
              ],
            ),
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

  Future<void> _sendDocument() async {
    try {
      setState(() => _isSending = true);
      final response = await replaceDocument(
        documentId: widget.documentId,
        filePath: _currentPdfPath,
      );

      if (response['success'] == true) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Dokumen berhasil dikirim!'),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
          (route) => false,
        );
      } else {
        // --- TAMBAHKAN BLOK INI ---
        // Memberi tahu pengguna bahwa pengiriman gagal berdasarkan pesan dari server.
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal mengirim dokumen.'),
            backgroundColor: Colors.red,
          ),
        );
        // ----------------------------
      }
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Edit', style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF172B4C),
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }

  Future<void> _showCancelConfirmationDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('token');

    if (authToken == null) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Token autentikasi tidak ditemukan')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Dokumen'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan dokumen ini? Semua data akan dihapus permanen.',
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
                    await _cancelDocumentRequest(authToken);
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

  Future<void> _cancelDocumentRequest(String authToken) async {
    try {
      setState(() => _isProcessing = true);
      final response = await cancelDocument(widget.documentId);

      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('document_id');

        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Dokumen berhasil dibatalkan'),
          ),
        );

        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
          (route) => false,
        );
      } else {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal membatalkan dokumen'),
          ),
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

  Future<void> _saveAllQrCodesToPdf() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final scaffold = scaffoldMessengerKey.currentState;
      scaffold?.showSnackBar(
        const SnackBar(content: Text('Menyimpan QR ke PDF...')),
      );

      final originalFileBytes = await File(widget.filePath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: originalFileBytes);

      final unlockedQrs = qrCodes.where((q) => q['locked'] != true).toList();

      if (unlockedQrs.isEmpty) {
        scaffold?.showSnackBar(
          const SnackBar(content: Text('Tidak ada QR yang perlu disimpan')),
        );
        return;
      }

      for (final qr in unlockedQrs) {
        final qrPainter = QrPainter.withQr(
          qr: QrValidator.validate(
            data: "${baseUrl}/view/${qr['sign_token']}",
            version: QrVersions.auto,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ).qrCode!,
          gapless: true,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
        );

        final ui.Image qrImage = await qrPainter.toImage(
          PdfViewerPage.qrPdfSize,
        );
        final ByteData? byteData = await qrImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData == null) continue;

        final Uint8List bytes = byteData.buffer.asUint8List();
        final PdfBitmap pdfImage = PdfBitmap(bytes);

        final int pageIndex = (qr['selected_page'] ?? 1) - 1;
        if (pageIndex < 0 || pageIndex >= document.pages.count) continue;

        final PdfPage pdfPage = document.pages[pageIndex];
        final Offset position = qr['position'] ?? Offset.zero;

        final double zoomLevel = pdfViewerController.zoomLevel;
        final Size pageSize = pdfPage.size;
        final Size viewSize = _pdfViewerKey.currentContext?.size ?? Size.zero;

        final double scaleX = pageSize.width / (viewSize.width * zoomLevel);
        final double scaleY = pageSize.height / (viewSize.height * zoomLevel);

        final double pdfX = position.dx * scaleX;
        final double pdfY = position.dy * scaleY;
        final double qrSizeInPdf = PdfViewerPage.qrPdfSize * scaleX;

        pdfPage.graphics.drawImage(
          pdfImage,
          Rect.fromLTWH(
            pdfX.clamp(0, pageSize.width - qrSizeInPdf),
            pdfY.clamp(0, pageSize.height - qrSizeInPdf),
            qrSizeInPdf,
            qrSizeInPdf,
          ),
        );
      }

      final tempPath =
          '${Directory.systemTemp.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) {
              final unlockedQr = qrCodes.firstWhere(
                (q) => q['locked'] != true,
                orElse: () => {},
              );

              if (unlockedQr.isNotEmpty) {
                final pdfViewerSize =
                    _pdfViewerKey.currentContext?.size ?? Size.zero;
                final newPosition = Offset(
                  details.localPosition.dx.clamp(
                    0.0,
                    pdfViewerSize.width - PdfViewerPage.qrDisplaySize,
                  ),
                  details.localPosition.dy.clamp(
                    0.0,
                    pdfViewerSize.height - PdfViewerPage.qrDisplaySize,
                  ),
                );

                if (_isValidPosition(newPosition, pdfViewerSize)) {
                  setState(() {
                    unlockedQr['position'] = newPosition;
                    unlockedQr['selected_page'] =
                        pdfViewerController.pageNumber;
                  });
                }
              }
            },
            child: SfPdfViewer.file(
              File(_currentPdfPath),
              key: _pdfViewerKey,
              controller: pdfViewerController,
            ),
          ),
          ...qrCodes.where((qr) => !qr['locked']).map((qr) {
            return Positioned(
              left: qr['position']?.dx ?? 0,
              top: qr['position']?.dy ?? 0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final pdfViewerSize =
                      _pdfViewerKey.currentContext?.size ?? Size.zero;
                  final newPosition =
                      Offset(
                        (qr['position']?.dx ?? 0) + details.delta.dx,
                        (qr['position']?.dy ?? 0) + details.delta.dy,
                      ).clamp(
                        Offset.zero,
                        Offset(
                          pdfViewerSize.width - PdfViewerPage.qrDisplaySize,
                          pdfViewerSize.height - PdfViewerPage.qrDisplaySize,
                        ),
                      );

                  setState(() => qr['position'] = newPosition);
                },
                child: Container(
                  width: PdfViewerPage.qrDisplaySize,
                  height: PdfViewerPage.qrDisplaySize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: QrImageView(
                    data: "${baseUrl}/view/${qr['sign_token']}",
                    size: PdfViewerPage.qrDisplaySize,
                  ),
                ),
              ),
            );
          }).toList(),
          _buildBottomNavigation(),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: Visibility(
        visible: !_isProcessing,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 70.0),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.white,
            onPressed: () async {
              if (qrCodes.any((q) => !q['locked'])) {
                await _saveAllQrCodesToPdf();
              } else {
                final result = await showInputDialog(
                  context: context,
                  formKey: _formKey,
                  nipController: nipController,
                  tujuanController: tujuanController,
                  showTujuan: true,
                  totalPages: pdfViewerController.pageCount,
                  documentId: widget.documentId,
                );

                if (result != null && result['sign_token'] != null) {
                  setState(() {
                    qrCodes.add({
                      'sign_token': result['sign_token'],
                      'selected_page': result['selected_page'],
                      'position': Offset(
                        MediaQuery.of(context).size.width / 2 -
                            PdfViewerPage.qrDisplaySize / 2,
                        MediaQuery.of(context).size.height / 2 -
                            PdfViewerPage.qrDisplaySize / 2,
                      ),
                      'locked': false,
                    });
                  });
                }
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            label: Text(
              qrCodes.any((q) => !q['locked'])
                  ? 'Simpan Semua QR'
                  : '+ Tanda Tangan',
              style: const TextStyle(color: Colors.black),
            ),
            icon: Icon(
              qrCodes.any((q) => !q['locked']) ? Icons.save : Icons.edit,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
