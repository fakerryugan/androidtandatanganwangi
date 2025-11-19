// ==========================================================
//                   PDF VIEWER FULL TANPA BLOC
// ==========================================================

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:android/api/token.dart';
import 'package:android/features/dashboard/view/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf_lib;
import 'package:pdfx/pdfx.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:android/upload_file/generateqr.dart';
import 'package:http_parser/http_parser.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();

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

  Rect? _pdfPageBoundsOnScreen;

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

  @override
  void dispose() {
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

        for (var controller in _transformationControllers) {
          controller.addListener(_updatePdfPageBounds);
        }

        _isLoadingPdf = false;
      });

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

  Future<void> _saveActiveQrToPdf() async {
    if (_activeQrNotifier.value == null || _isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final qrToSave = _activeQrNotifier.value!;
      final int pageIndex = (qrToSave['selected_page'] as int) - 1;

      final GlobalKey pageKey = _pageKeys[pageIndex];
      final RenderBox? pageRenderBox =
          pageKey.currentContext?.findRenderObject() as RenderBox?;
      if (pageRenderBox == null || !pageRenderBox.hasSize) {
        throw Exception('Gagal mengukur area PDF.');
      }

      final TransformationController controller =
          _transformationControllers[pageIndex];
      final Matrix4 matrix = controller.value;

      final Size unscaledImageSize = pageRenderBox.size;
      final Offset imagePositionOnScreen = pageRenderBox.localToGlobal(
        Offset.zero,
      );
      final Offset qrPositionOnScreen = qrToSave['position'] as Offset;
      final double qrSizeOnScreen = qrToSave['size'] as double;
      final String signToken = qrToSave['sign_token'] as String;

      final Matrix4 invertedMatrix = Matrix4.inverted(matrix);
      final Offset qrPositionRelativeToImageContainer =
          qrPositionOnScreen - imagePositionOnScreen;

      final Offset qrPositionOnUnscaledImage = MatrixUtils.transformPoint(
        invertedMatrix,
        qrPositionRelativeToImageContainer,
      );

      final double currentScale = matrix.getMaxScaleOnAxis();
      final double qrSizeOnUnscaledImage = qrSizeOnScreen / currentScale;

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

      final originalFileBytes = await File(_currentPdfPath).readAsBytes();
      final pdf_lib.PdfDocument document = pdf_lib.PdfDocument(
        inputBytes: originalFileBytes,
      );

      final pdf_lib.PdfPage pdfPage = document.pages[pageIndex];
      final pdf_lib.PdfGraphics graphics = pdfPage.graphics;

      final imageBytes = await QrPainter(
        data: signToken,
        version: QrVersions.auto,
        gapless: true,
      ).toImageData(2048);

      if (imageBytes == null) throw Exception('Gagal membuat QR.');

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

      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('QR berhasil disimpan!')),
      );
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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

                // QR sementara
                ValueListenableBuilder<Map<String, dynamic>?>(
                  valueListenable: _activeQrNotifier,
                  builder: (context, activeQr, child) {
                    if (activeQr == null) return const SizedBox.shrink();
                    return ResizableQrCode(
                      key: ValueKey('qr_${activeQr['sign_token']}'),
                      boundaryRect: _pdfPageBoundsOnScreen,
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

  // ==============================================================
  // TAMBAH QR BARU
  // ==============================================================

  void _addNewQrCode() async {
    if (_activeQrNotifier.value != null) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Selesaikan tanda tangan yang ada dulu.')),
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

      if (_pdfPageBoundsOnScreen != null) {
        final boundary = _pdfPageBoundsOnScreen!;
        final double centerX = boundary.left + (boundary.width / 2);
        final double centerY = boundary.top + (boundary.height / 2);

        initialPosition = Offset(
          centerX - (_initialQrSize / 2),
          centerY - (_initialQrSize / 2),
        );

        initialPosition = Offset(
          initialPosition.dx.clamp(
            boundary.left,
            boundary.right - _initialQrSize,
          ),
          initialPosition.dy.clamp(
            boundary.top,
            boundary.bottom - _initialQrSize,
          ),
        );
      } else {
        final viewSize = MediaQuery.of(context).size;
        initialPosition = Offset(
          viewSize.width / 2 - _initialQrSize / 2,
          viewSize.height / 3,
        );
      }

      _activeQrNotifier.value = {
        'sign_token': result['sign_token'],
        'selected_page': result['selected_page'],
        'position': initialPosition,
        'size': _initialQrSize,
        'locked': false,
      };

      final targetPage = (result['selected_page'] as int) - 1;

      if (targetPage >= 0 && targetPage < totalPages) {
        if (_pageController.page?.round() != targetPage) {
          _pageController.jumpToPage(targetPage);
        }
      }
    }
  }

  // ==============================================================
  // KIRIM DOKUMEN KE SERVER
  // ==============================================================

  Future<void> _sendDocument() async {
    try {
      setState(() => _isSending = true);

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');

      if (authToken == null) throw Exception('Token tidak valid');

      final uri = Uri.parse('$baseUrl/documents/replace/${widget.documentId}');

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $authToken';

      request.files.add(
        await http.MultipartFile.fromPath(
          'pdf',
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
            MaterialPageRoute(builder: (_) => const DashboardPage()),
            (route) => false,
          );
        }
      } else {
        throw Exception(jsonDecode(responseBody)['message']);
      }
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ==============================================================
  // KONFIRMASI BATALKAN DOKUMEN
  // ==============================================================

  Future<void> _showCancelConfirmationDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Dokumen'),
        content: const Text('Yakin ingin membatalkan dokumen ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: _isProcessing
                ? null
                : () {
                    Navigator.of(context).pop();
                    _cancelDocumentDirect();
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

  // ==============================================================
  // BATALKAN DOKUMEN (Direct HTTP, tanpa Bloc)
  // ==============================================================

  Future<void> _cancelDocumentDirect() async {
    setState(() => _isProcessing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) throw Exception("Token tidak ditemukan");

      final url = Uri.parse('$baseUrl/documents/cancel/${widget.documentId}');
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.green,
          ),
        );

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardPage()),
            (route) => false,
          );
        }
      } else {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(data['message']), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class ResizableQrCode extends StatefulWidget {
  final Map<String, dynamic> qrData;
  final BoxConstraints constraints;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<double> onResizeUpdate;
  final VoidCallback onDragEnd;
  final Rect? boundaryRect;

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

  void _onPanUpdate(DragUpdateDetails details) {
    Offset newPosition = _position + details.delta;

    if (widget.boundaryRect != null) {
      final boundary = widget.boundaryRect!;
      newPosition = Offset(
        newPosition.dx.clamp(boundary.left, boundary.right - _size),
        newPosition.dy.clamp(boundary.top, boundary.bottom - _size),
      );
    }

    setState(() => _position = newPosition);
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
            Positioned(
              right: -10,
              bottom: -10,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final newSize =
                        _size + (details.delta.dx + details.delta.dy) / 2;
                    _size = newSize.clamp(50.0, 300.0);
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
