import 'dart:io';
import 'dart:typed_data';
import 'package:android/features/dashboard/view/menu_home.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart'
    as pdf_lib; // Library untuk MENULIS PDF
import 'package:pdfx/pdfx.dart'; // Library untuk MEMBACA & MERENDER PDF
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http_parser/http_parser.dart';
import 'dart:convert';

// Pastikan Anda memiliki referensi yang benar ke file-file ini
import '../api/token.dart';
import 'package:android/upload_file/generateqr.dart';

// Kunci global untuk ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();

// =========================================================================
// WIDGET UTAMA: PdfViewerPage
// =========================================================================

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final int documentId;
  final Map<String, dynamic>? qrData;

  const PdfViewerPage({
    super.key,
    required this.filePath,
    required this.documentId,
    this.qrData,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PageController _pageController = PageController();
  bool _isLoadingPdf = true;
  List<Uint8List> _pageImages = [];
  List<Size> _pdfPageSizes = [];
  List<GlobalKey> _pageKeys = [];
  List<TransformationController> _transformationControllers = [];

  // State untuk menyimpan batasan area PDF di layar (pagar tak terlihat)
  Rect? _pdfPageBoundsOnScreen;

  final ValueNotifier<Map<String, dynamic>?> _activeQrNotifier = ValueNotifier(
    null,
  );
  List<Map<String, dynamic>> qrCodes = [];
  bool _isProcessing = false;
  final bool _isSending = false;
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

  @override
  void dispose() {
    // Pastikan semua controller dibersihkan untuk menghindari memory leak
    for (var controller in _transformationControllers) {
      controller.removeListener(_updatePdfPageBounds);
      controller.dispose();
    }
    _pageController.dispose();
    _activeQrNotifier.dispose();
    nipController.dispose();
    tujuanController.dispose();
    super.dispose();
  }

  /// Fungsi untuk menghitung dan memperbarui batasan "pagar" di sekitar PDF.
  void _updatePdfPageBounds() {
    if (_pageKeys.isEmpty || !_pageController.hasClients) return;

    final int currentPageIndex = _pageController.page?.round() ?? 0;
    if (currentPageIndex >= _pageKeys.length) return;

    final key = _pageKeys[currentPageIndex];
    final context = key.currentContext;
    if (context == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final newBounds = Rect.fromLTWH(
      position.dx,
      position.dy,
      size.width,
      size.height,
    );

    if (_pdfPageBoundsOnScreen != newBounds) {
      setState(() {
        _pdfPageBoundsOnScreen = newBounds;
      });
    }
  }

  /// Memuat file PDF dan mengubah setiap halaman menjadi gambar.
  Future<void> _loadAndConvertPdf() async {
    setState(() => _isLoadingPdf = true);
    try {
      final document = await PdfDocument.openFile(widget.filePath);
      final images = <Uint8List>[];
      final pageSizes = <Size>[];

      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        final pageImage = await page.render(
          width: page.width * 2, // Resolusi tinggi untuk kualitas zoom
          height: page.height * 2,
          format: PdfPageImageFormat.png,
        );
        if (pageImage != null) {
          images.add(pageImage.bytes);
          pageSizes.add(Size(page.width, page.height));
        }
        await page.close();
      }

      // Bersihkan listener lama sebelum membuat yang baru
      for (var controller in _transformationControllers) {
        controller.removeListener(_updatePdfPageBounds);
        controller.dispose();
      }

      setState(() {
        _pageImages = images;
        _pdfPageSizes = pageSizes;
        _pageKeys = List.generate(images.length, (_) => GlobalKey());
        _transformationControllers = List.generate(
          images.length,
          (_) => TransformationController(),
        );

        // Tambahkan listener ke setiap controller untuk melacak zoom/pan
        for (var controller in _transformationControllers) {
          controller.addListener(_updatePdfPageBounds);
        }

        _isLoadingPdf = false;
      });

      // Panggil sekali setelah build pertama selesai untuk set batasan awal
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updatePdfPageBounds(),
      );
    } catch (e) {
      setState(() => _isLoadingPdf = false);
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Gagal memuat PDF: ${e.toString()}')),
      );
    }
  }

  /// Logika utama untuk menyimpan QR code ke dalam file PDF.
  Future<void> _saveActiveQrToPdf() async {
    if (_activeQrNotifier.value == null || _isProcessing) return;
    setState(() => _isProcessing = true);
    final scaffold = scaffoldMessengerKey.currentState;

    try {
      final qrToSave = _activeQrNotifier.value!;
      final int pageIndex = (qrToSave['selected_page'] as int) - 1;

      // 1. Dapatkan RenderBox dari gambar PDF.
      final GlobalKey pageKey = _pageKeys[pageIndex];
      final RenderBox? pageRenderBox =
          pageKey.currentContext?.findRenderObject() as RenderBox?;
      if (pageRenderBox == null || !pageRenderBox.hasSize) {
        throw Exception('Gagal mengukur area PDF. Coba lagi.');
      }

      // 2. Dapatkan matriks transformasi (zoom/pan) dari controller.
      final TransformationController controller =
          _transformationControllers[pageIndex];
      final Matrix4 matrix = controller.value;

      // 3. Dapatkan data posisi dan ukuran.
      final Size unscaledImageSize = pageRenderBox.size;
      final Offset imagePositionOnScreen = pageRenderBox.localToGlobal(
        Offset.zero,
      );
      final Offset qrPositionOnScreen = qrToSave['position'] as Offset;
      final double qrSizeOnScreen = qrToSave['size'] as double;
      final String signToken = qrToSave['sign_token'] as String;

      // 4. Konversi posisi QR di layar ke posisi relatif di gambar (sebelum di-zoom)
      final Matrix4 invertedMatrix = Matrix4.inverted(matrix);
      final Offset qrPositionRelativeToImageContainer =
          qrPositionOnScreen - imagePositionOnScreen;
      final Offset qrPositionOnUnscaledImage = MatrixUtils.transformPoint(
        invertedMatrix,
        qrPositionRelativeToImageContainer,
      );

      // 5. Hitung ukuran QR pada gambar yang belum di-zoom.
      final double currentScale = matrix.getMaxScaleOnAxis();
      final double qrSizeOnUnscaledImage = qrSizeOnScreen / currentScale;

      // 6. Konversi koordinat gambar ke koordinat PDF asli (dalam points).
      final Size originalPdfPageSize = _pdfPageSizes[pageIndex];
      final double scaleFactor =
          originalPdfPageSize.width / unscaledImageSize.width;
      final double pdfX = qrPositionOnUnscaledImage.dx * scaleFactor;
      final double pdfY = qrPositionOnUnscaledImage.dy * scaleFactor;
      final double qrSizeInPdf = qrSizeOnUnscaledImage * scaleFactor;

      final Rect finalRect = Rect.fromLTWH(
        pdfX,
        pdfY,
        qrSizeInPdf,
        qrSizeInPdf,
      );

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

      // Ganti file lama dengan file baru yang sudah ada QR
      await File(_currentPdfPath).delete();
      await File(tempPath).rename(_currentPdfPath);

      setState(() {
        qrCodes.add({...qrToSave, 'locked': true});
        _activeQrNotifier.value = null;
        _isLoadingPdf = true;
      });

      await _loadAndConvertPdf(); // Muat ulang PDF yang sudah diperbarui

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
                      transformationController:
                          _transformationControllers[index],
                      minScale: 1.0,
                      maxScale: 4.0,
                      onInteractionEnd: (_) => _updatePdfPageBounds(),
                      child: Container(
                        key: _pageKeys[index],
                        alignment: Alignment.center,
                        child: Image.memory(_pageImages[index]),
                      ),
                    );
                  },
                  onPageChanged: (page) {
                    if (_activeQrNotifier.value != null) {
                      _activeQrNotifier.value = {
                        ..._activeQrNotifier.value!,
                        'selected_page': page + 1,
                      };
                    }
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _updatePdfPageBounds(),
                    );
                  },
                ),

                ValueListenableBuilder<Map<String, dynamic>?>(
                  valueListenable: _activeQrNotifier,
                  builder: (context, activeQr, child) {
                    if (activeQr == null) return const SizedBox.shrink();

                    // Kirimkan "pagar" ke widget QR code
                    return ResizableQrCode(
                      key: ValueKey('resizable_qr_${activeQr['sign_token']}'),
                      boundaryRect:
                          _pdfPageBoundsOnScreen, // <-- Kunci pembatasan
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

  // --- Widget dan Fungsi Bantuan (Tidak ada perubahan signifikan) ---
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

  // GANTI FUNGSI INI DI DALAM CLASS _PdfViewerPageState

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
      Offset initialPosition;

      // ✨ PERBAIKAN UTAMA: Hitung posisi tengah dari area PDF yang terlihat
      if (_pdfPageBoundsOnScreen != null) {
        final boundary = _pdfPageBoundsOnScreen!;

        // 1. Temukan titik tengah dari "pagar" PDF yang terlihat di layar
        final double centerX = boundary.left + (boundary.width / 2);
        final double centerY = boundary.top + (boundary.height / 2);

        // 2. Tempatkan QR code di tengah area tersebut
        initialPosition = Offset(
          centerX - (_initialQrSize / 2),
          centerY - (_initialQrSize / 2),
        );

        // 3. (Pengaman) Pastikan posisi yang dihitung tidak keluar batas.
        //    Ini penting jika ukuran QR lebih besar dari area PDF yang terlihat.
        final double clampedDx = initialPosition.dx.clamp(
          boundary.left,
          boundary.right - _initialQrSize,
        );
        final double clampedDy = initialPosition.dy.clamp(
          boundary.top,
          boundary.bottom - _initialQrSize,
        );
        initialPosition = Offset(clampedDx, clampedDy);
      } else {
        // Fallback jika area PDF belum terdeteksi: tempatkan di tengah layar
        final viewSize = MediaQuery.of(context).size;
        initialPosition = Offset(
          viewSize.width / 2 - _initialQrSize / 2,
          viewSize.height / 3,
        );
      }

      // Set state dengan posisi yang sudah dijamin pas
      _activeQrNotifier.value = {
        'sign_token': result['sign_token'],
        'selected_page': result['selected_page'],
        'position':
            initialPosition, // <-- Menggunakan posisi yang sudah dihitung
        'size': _initialQrSize,
        'locked': false,
      };

      // Pindahkan ke halaman yang dipilih
      final targetPage = (result['selected_page'] as int) - 1;
      if (targetPage >= 0 && targetPage < totalPages) {
        if (_pageController.page?.round() != targetPage) {
          _pageController.jumpToPage(targetPage);
        }
      }
    }
  }

  Future<void> _sendDocument() async {
    // ... (Logika pengiriman file tidak berubah)
  }

  Future<void> _showCancelConfirmationDialog() async {
    // ... (Logika dialog batal tidak berubah)
  }

  Future<void> _cancelDocumentRequest() async {
    // ... (Logika pembatalan dokumen tidak berubah)
  }
}

// =========================================================================
// WIDGET PEMBANTU: ResizableQrCode (Sebelumnya di resize.dart)
// =========================================================================

class ResizableQrCode extends StatefulWidget {
  final Map<String, dynamic> qrData;
  final BoxConstraints constraints;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<double> onResizeUpdate;
  final VoidCallback onDragEnd;
  final Rect? boundaryRect; // Parameter untuk menerima area batasan

  const ResizableQrCode({
    super.key,
    required this.qrData,
    required this.constraints,
    required this.onDragUpdate,
    required this.onResizeUpdate,
    required this.onDragEnd,
    this.boundaryRect,
  });

  @override
  _ResizableQrCodeState createState() => _ResizableQrCodeState();
}

class _ResizableQrCodeState extends State<ResizableQrCode> {
  late double _size;
  late Offset _position;

  @override
  void initState() {
    super.initState();
    _size = widget.qrData['size'] as double;
    _position = widget.qrData['position'] as Offset;
  }

  /// Menangani pergerakan (drag) QR code dan membatasinya di dalam "pagar".
  void _onPanUpdate(DragUpdateDetails details) {
    Offset newPosition = _position + details.delta;

    // Jika ada batasan (boundaryRect), patuhi!
    if (widget.boundaryRect != null) {
      final boundary = widget.boundaryRect!;

      // Batasi posisi X agar tidak keluar dari sisi kiri dan kanan
      final double clampedDx = newPosition.dx.clamp(
        boundary.left,
        boundary.right - _size,
      );

      // Batasi posisi Y agar tidak keluar dari sisi atas dan bawah
      final double clampedDy = newPosition.dy.clamp(
        boundary.top,
        boundary.bottom - _size,
      );

      newPosition = Offset(clampedDx, clampedDy);
    }

    setState(() {
      _position = newPosition;
    });
    widget.onDragUpdate(_position);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: (_) => widget.onDragEnd(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                color: Colors.white,
              ),
              child: QrImageView(
                data: widget.qrData['sign_token'] as String,
                version: QrVersions.auto,
                size: _size,
              ),
            ),
            // Handle untuk resize
            Positioned(
              right: -10,
              bottom: -10,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final newSize =
                        _size + (details.delta.dx + details.delta.dy) / 2;
                    _size = newSize.clamp(50.0, 300.0); // Batasi ukuran
                  });
                  widget.onResizeUpdate(_size);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.zoom_out_map,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
