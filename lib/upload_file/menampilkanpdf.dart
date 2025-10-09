// menampilkanpdf.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart'
    as pdf_lib; // Library untuk MENULIS PDF
import 'package:pdfx/pdfx.dart'; // ✅ BARU: Library untuk MEMBACA & MERENDER PDF
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

import '../api/token.dart';
import 'package:android/upload_file/generateqr.dart';
import 'package:android/upload_file/resize.dart';
import 'package:android/bottom_navbar/bottom_navbar.dart';

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
  final PageController _pageController = PageController();

  bool _isLoadingPdf = true;
  List<Uint8List> _pageImages = [];
  List<Size> _pdfPageSizes = [];

  final ValueNotifier<Map<String, dynamic>?> _activeQrNotifier = ValueNotifier(
    null,
  );
  List<Map<String, dynamic>> qrCodes = [];
  bool _isProcessing = false;
  bool _isSending = false;
  late String _currentPdfPath;

  static const double _initialQrSize = 100.0;

  @override
  void initState() {
    super.initState();
    _currentPdfPath = widget.filePath;
    _loadAndConvertPdf();

    if (widget.qrData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final viewSize = MediaQuery.of(context).size;
        _activeQrNotifier.value = {
          ...widget.qrData!,
          'position': Offset(
            viewSize.width / 2 - _initialQrSize / 2,
            viewSize.height / 3,
          ),
          'size': _initialQrSize,
          'locked': false,
          'selected_page': 1,
        };
      });
    }
  }

  Future<void> _loadAndConvertPdf() async {
    setState(() => _isLoadingPdf = true);
    try {
      final document = await PdfDocument.openFile(widget.filePath);

      final images = <Uint8List>[];
      final pageSizes = <Size>[];

      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        final pageImage = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.png,
        );

        if (pageImage != null) {
          images.add(pageImage.bytes);
          pageSizes.add(Size(page.width, page.height));
        }
        await page.close();
      }

      setState(() {
        _pageImages = images;
        _pdfPageSizes = pageSizes;
        _isLoadingPdf = false;
      });
    } catch (e) {
      setState(() => _isLoadingPdf = false);
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Gagal memuat PDF: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveActiveQrToPdf() async {
    if (_activeQrNotifier.value == null || _isProcessing) return;
    setState(() => _isProcessing = true);
    final scaffold = scaffoldMessengerKey.currentState;

    try {
      final qrToSave = _activeQrNotifier.value!;
      final viewSize = context.size;

      if (viewSize == null) throw Exception('Gagal mendapatkan ukuran view.');

      scaffold?.showSnackBar(
        const SnackBar(content: Text('Menyimpan QR ke PDF...')),
      );

      final originalFileBytes = await File(_currentPdfPath).readAsBytes();
      final pdf_lib.PdfDocument document = pdf_lib.PdfDocument(
        inputBytes: originalFileBytes,
      );

      final int pageIndex = (qrToSave['selected_page'] as int) - 1;
      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        throw Exception('Halaman #${pageIndex + 1} tidak valid.');
      }
      final pdf_lib.PdfPage pdfPage = document.pages[pageIndex];
      final Size pdfPageSize = _pdfPageSizes[pageIndex];
      final pdf_lib.PdfGraphics graphics = pdfPage.graphics;

      final Offset positionOnScreen = qrToSave['position'] as Offset;
      final double sizeOnScreen = qrToSave['size'] as double;
      final String signToken = qrToSave['sign_token'] as String;

      // --- LOGIKA PERHITUNGAN ASPECT RATIO (TIDAK BERUBAH) ---
      final double viewAspectRatio = viewSize.width / viewSize.height;
      final double pdfPageAspectRatio = pdfPageSize.width / pdfPageSize.height;
      Size renderedImageSize;
      Offset imagePadding;
      if (pdfPageAspectRatio > viewAspectRatio) {
        renderedImageSize = Size(
          viewSize.width,
          viewSize.width / pdfPageAspectRatio,
        );
        imagePadding = Offset(
          0,
          (viewSize.height - renderedImageSize.height) / 2,
        );
      } else {
        renderedImageSize = Size(
          viewSize.height * pdfPageAspectRatio,
          viewSize.height,
        );
        imagePadding = Offset(
          (viewSize.width - renderedImageSize.width) / 2,
          0,
        );
      }

      // --- ✅ BLOK PERHITUNGAN KOORDINAT YANG SUDAH DIPERBAIKI ---
      // Koreksi untuk status bar dan AppBar. Sesuaikan nilai ini jika posisi vertikal masih sedikit meleset.
      // --- ✅ BLOK PERHITUNGAN KOORDINAT YANG SUDAH DIPERBAIKI ---
      final Offset positionOnImage = Offset(
        positionOnScreen.dx - imagePadding.dx,
        positionOnScreen.dy - imagePadding.dy,
      );

      final double scale = pdfPageSize.width / renderedImageSize.width;

      // ✅ TAMBAHKAN KOREKSI DINAMIS DI SINI
      // Ubah angka 0.5 (50%) ini jika perlu untuk penyesuaian.
      const double FAKTOR_KOREKSI_Y = 0.5;
      final double koreksiDinamis = kToolbarHeight * FAKTOR_KOREKSI_Y;

      final double pdfX = positionOnImage.dx * scale;
      // ✅ UBAH BARIS INI untuk menerapkan koreksi
      final double pdfY = (positionOnImage.dy * scale) + koreksiDinamis;
      final double qrSizeInPdf = sizeOnScreen * scale;

      // Buat Rect untuk digambar dengan origin di KIRI ATAS.
      final Rect finalRect = Rect.fromLTWH(
        pdfX,
        pdfY,
        qrSizeInPdf,
        qrSizeInPdf,
      );

      debugPrint("Rect Final yang digambar: $finalRect");

      final imageBytes = await QrPainter(
        data: signToken,
        version: QrVersions.auto,
        gapless: true,
      ).toImageData(2048);
      if (imageBytes == null) throw Exception('Gagal membuat gambar QR.');
      final pdf_lib.PdfBitmap pdfImage = pdf_lib.PdfBitmap(
        imageBytes.buffer.asUint8List(),
      );

      graphics.drawImage(pdfImage, finalRect);

      // --- SISA KODE (TIDAK BERUBAH) ---
      final tempPath =
          '${Directory.systemTemp.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(tempPath).writeAsBytes(await document.save());
      document.dispose();

      await File(_currentPdfPath).delete();
      await File(tempPath).rename(_currentPdfPath);

      setState(() {
        qrCodes.add({...qrToSave, 'locked': true});
        _activeQrNotifier.value = null;
        _isLoadingPdf = true;
      });

      await _loadAndConvertPdf();

      scaffold?.showSnackBar(
        const SnackBar(content: Text('QR berhasil disimpan!')),
      );
    } catch (e) {
      scaffold?.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldMessengerKey,
      appBar: _buildAppBar(),
      body: _isLoadingPdf
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _pageImages.length,
                  itemBuilder: (context, index) {
                    return InteractiveViewer(
                      child: Image.memory(_pageImages[index]),
                    );
                  },
                  onPageChanged: (page) {
                    if (_activeQrNotifier.value != null) {
                      _activeQrNotifier.value = {
                        ..._activeQrNotifier.value!,
                        'selected_page': page + 1, // Halaman 1-based
                      };
                    }
                  },
                ),

                ValueListenableBuilder<Map<String, dynamic>?>(
                  valueListenable: _activeQrNotifier,
                  builder: (context, activeQr, child) {
                    if (activeQr == null) return const SizedBox.shrink();
                    return ResizableQrCode(
                      key: ValueKey('resizable_qr_${activeQr['sign_token']}'),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
                        maxHeight: MediaQuery.of(context).size.height,
                      ),
                      qrData: activeQr,
                      onDragUpdate: (newPosition) {
                        _activeQrNotifier.value = {
                          ...activeQr,
                          'position': newPosition,
                        };
                      },
                      onResizeUpdate: (newSize) {
                        _activeQrNotifier.value = {
                          ...activeQr,
                          'size': newSize,
                        };
                      },
                      onDragEnd: () {
                        final currentPage = _pageController.page?.round() ?? 0;
                        _activeQrNotifier.value = {
                          ..._activeQrNotifier.value!,
                          'selected_page': currentPage + 1,
                        };
                      },
                    );
                  },
                ),

                if (_isProcessing || _isSending)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),

                _buildBottomNavigation(),
              ],
            ),
      floatingActionButton: ValueListenableBuilder<Map<String, dynamic>?>(
        valueListenable: _activeQrNotifier,
        builder: (context, activeQr, _) {
          final hasActiveQr = activeQr != null;
          return Visibility(
            visible: !_isProcessing && !_isSending,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 70.0),
              child: FloatingActionButton.extended(
                backgroundColor: Colors.white,
                onPressed: () {
                  if (hasActiveQr) {
                    _saveActiveQrToPdf();
                  } else {
                    _addNewQrCode();
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                label: Text(
                  hasActiveQr ? 'Simpan Posisi QR' : 'Tanda Tangan',
                  style: const TextStyle(color: Colors.black),
                ),
                icon: Icon(
                  hasActiveQr ? Icons.save : Icons.add,
                  color: Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Sisa Widget dan Fungsi (tidak ada perubahan signifikan) ---
  final TextEditingController nipController = TextEditingController();
  final TextEditingController tujuanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  AppBar _buildAppBar() => AppBar(
    title: const Text(
      'Edit & Tanda Tangan',
      style: TextStyle(color: Colors.white),
    ),
    backgroundColor: const Color(0xFF172B4C),
    centerTitle: true,
    automaticallyImplyLeading: false,
  );

  Widget _buildBottomNavigation() {
    final canSend = _activeQrNotifier.value == null && qrCodes.isNotEmpty;
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
            children: [_buildBackButton(), if (canSend) _buildSendButton()],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: IconButton(
      icon: const Icon(Icons.arrow_back_outlined, color: Color(0xFF172B4C)),
      onPressed: _showCancelConfirmationDialog,
    ),
  );

  Widget _buildSendButton() => Container(
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

  void _addNewQrCode() async {
    if (_activeQrNotifier.value != null) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Selesaikan tanda tangan yang ada terlebih dahulu.'),
        ),
      );
      return;
    }
    final totalPages = _pageImages.length;
    final result = await showInputDialog(
      context: context,
      formKey: _formKey,
      nipController: nipController,
      tujuanController: tujuanController,
      showTujuan: true,
      totalPages: totalPages,
      documentId: widget.documentId,
    );
    if (result != null && result['sign_token'] != null) {
      final viewSize = MediaQuery.of(context).size;
      _activeQrNotifier.value = {
        'sign_token': result['sign_token'],
        'selected_page': result['selected_page'],
        'position': Offset(
          viewSize.width / 2 - _initialQrSize / 2,
          viewSize.height / 3,
        ),
        'size': _initialQrSize,
        'locked': false,
      };
      final targetPage = (result['selected_page'] as int) - 1;
      if (targetPage >= 0 && targetPage < totalPages) {
        _pageController.jumpToPage(targetPage);
      }
    }
  }

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
          'pdf',
          _currentPdfPath,
          contentType: MediaType('application', 'pdf'),
        ),
      );
      var response = await request.send();
      if (response.statusCode == 200) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Dokumen berhasil dikirim!')),
        );
        if (mounted)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
            (route) => false,
          );
      } else {
        var responseBody = await response.stream.bytesToString();
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

  Future<void> _showCancelConfirmationDialog() async => await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Batalkan Dokumen'),
      content: const Text('Apakah Anda yakin ingin membatalkan dokumen ini?'),
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
        if (mounted)
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
            (route) => false,
          );
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
