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

// GANTI SELURUH CLASS _PdfViewerPageState ANDA DENGAN INI

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PageController _pageController = PageController();

  bool _isLoadingPdf = true;
  List<Uint8List> _pageImages = [];
  List<Size> _pdfPageSizes = [];

  // ✅ BARU: Daftar GlobalKey untuk mengukur setiap halaman PDF di layar
  List<GlobalKey> _pageKeys = [];

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
        // ✅ BARU: Inisialisasi GlobalKey sebanyak jumlah halaman
        _pageKeys = List.generate(images.length, (_) => GlobalKey());
        _isLoadingPdf = false;
      });
    } catch (e) {
      setState(() => _isLoadingPdf = false);
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Gagal memuat PDF: ${e.toString()}')),
      );
    }
  }

  // 👇 PERUBAHAN UTAMA ADA DI FUNGSI INI 👇
  Future<void> _saveActiveQrToPdf() async {
    if (_activeQrNotifier.value == null || _isProcessing) return;
    setState(() => _isProcessing = true);
    final scaffold = scaffoldMessengerKey.currentState;

    try {
      final qrToSave = _activeQrNotifier.value!;
      final int pageIndex = (qrToSave['selected_page'] as int) - 1;

      // --- 🎯 BLOK PENGUKURAN DAN PERHITUNGAN KOORDINAT BARU 🎯 ---

      // 1. Dapatkan RenderBox dari gambar PDF yang sedang ditampilkan menggunakan GlobalKey.
      //    RenderBox memberi kita ukuran dan posisi widget yang sebenarnya di layar.
      final GlobalKey pageKey = _pageKeys[pageIndex];
      final RenderBox? pageRenderBox =
          pageKey.currentContext?.findRenderObject() as RenderBox?;
      if (pageRenderBox == null || !pageRenderBox.hasSize) {
        throw Exception('Gagal mengukur area PDF. Coba lagi.');
      }

      // 2. Dapatkan batas (posisi dan ukuran) gambar PDF di layar.
      final pdfImageSizeOnScreen = pageRenderBox.size;
      final pdfImagePositionOnScreen = pageRenderBox.localToGlobal(Offset.zero);
      final Rect pdfImageBoundsOnScreen =
          pdfImagePositionOnScreen & pdfImageSizeOnScreen;

      // 3. Dapatkan data QR dari state.
      final Offset qrPositionOnScreen = qrToSave['position'] as Offset;
      final double qrSizeOnScreen = qrToSave['size'] as double;
      final String signToken = qrToSave['sign_token'] as String;

      // 4. Hitung posisi QR relatif terhadap pojok kiri atas *gambar PDF*, bukan layar.
      final Offset relativeQrPosition = Offset(
        qrPositionOnScreen.dx - pdfImageBoundsOnScreen.left,
        qrPositionOnScreen.dy - pdfImageBoundsOnScreen.top,
      );

      // 5. Hitung faktor skala antara ukuran PDF asli (dalam points) dan ukuran gambar di layar (dalam pixel).
      final Size originalPdfPageSize = _pdfPageSizes[pageIndex];
      final double scaleFactor =
          originalPdfPageSize.width / pdfImageSizeOnScreen.width;

      // 6. Konversikan posisi dan ukuran QR dari koordinat layar ke koordinat PDF.
      final double pdfX = relativeQrPosition.dx * scaleFactor;
      final double pdfY = relativeQrPosition.dy * scaleFactor;
      final double qrSizeInPdf = qrSizeOnScreen * scaleFactor;

      final Rect finalRect = Rect.fromLTWH(
        pdfX,
        pdfY,
        qrSizeInPdf,
        qrSizeInPdf,
      );

      debugPrint("--- Kalkulasi Posisi QR ---");
      debugPrint("Ukuran PDF Asli: $originalPdfPageSize");
      debugPrint("Batas Gambar di Layar: $pdfImageBoundsOnScreen");
      debugPrint("Posisi QR di Layar: $qrPositionOnScreen");
      debugPrint("Posisi QR Relatif: $relativeQrPosition");
      debugPrint("Faktor Skala: $scaleFactor");
      debugPrint("Rect Final di PDF: $finalRect");
      // --- AKHIR BLOK PENGUKURAN ---

      scaffold?.showSnackBar(
        const SnackBar(content: Text('Menyimpan QR ke PDF...')),
      );

      final originalFileBytes = await File(_currentPdfPath).readAsBytes();
      final pdf_lib.PdfDocument document = pdf_lib.PdfDocument(
        inputBytes: originalFileBytes,
      );

      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        throw Exception('Halaman #${pageIndex + 1} tidak valid.');
      }
      final pdf_lib.PdfPage pdfPage = document.pages[pageIndex];
      final pdf_lib.PdfGraphics graphics = pdfPage.graphics;

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
                    // ✅ BARU: Bungkus gambar dengan Container dan berikan Key
                    return InteractiveViewer(
                      child: Container(
                        key: _pageKeys[index], // <-- KUNCI PENGUKURAN
                        alignment: Alignment.center,
                        child: Image.memory(_pageImages[index]),
                      ),
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
                key: const Key('add_or_save_qr_button'),
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

  // --- Sisa Widget dan Fungsi (tidak ada perubahan signifikan, sama seperti kode Anda) ---
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
      print('🟢 [DEBUG] Tombol "Kirim Dokumen" ditekan');
      setState(() => _isSending = true);

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      print('🔑 [DEBUG] Token yang diambil: $authToken');

      if (authToken == null) throw Exception('Token tidak valid');

      final uri = Uri.parse('$baseUrl/documents/replace/${widget.documentId}');
      print('🌐 [DEBUG] URL tujuan: $uri');
      print('📄 [DEBUG] File yang akan dikirim: $_currentPdfPath');

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $authToken';

      request.files.add(
        await http.MultipartFile.fromPath(
          'pdf',
          _currentPdfPath,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      print('🚀 [DEBUG] Mengirim request ke server...');
      var response = await request.send();
      print('📩 [DEBUG] Status code: ${response.statusCode}');

      var responseBody = await response.stream.bytesToString();
      print('📦 [DEBUG] Body respon: $responseBody');

      if (response.statusCode == 200) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('✅ Dokumen berhasil dikirim!')),
        );
        print('✅ [DEBUG] Dokumen berhasil dikirim, pindah halaman...');
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
            (route) => false,
          );
        }
      } else {
        print('❌ [DEBUG] Gagal kirim dokumen: $responseBody');
        throw Exception(
          jsonDecode(responseBody)['message'] ?? 'Gagal mengirim dokumen',
        );
      }
    } catch (e) {
      print('💥 [DEBUG] Error saat kirim dokumen: $e');
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        print('🔁 [DEBUG] Selesai proses pengiriman dokumen');
      }
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
