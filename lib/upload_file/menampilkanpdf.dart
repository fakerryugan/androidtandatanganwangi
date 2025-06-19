import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:android/upload_file/generateqr.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api/token.dart';
import 'package:android/bottom_navbar/bottom_navbar.dart';
import 'package:http_parser/http_parser.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final int documentId;
  final Map<String, dynamic>? qrData;
  final bool qrLocked;

  static const double qrDisplaySize = 100.0;
  static const double qrPdfSize = 100.0;

  const PdfViewerPage({
    Key? key,
    required this.filePath,
    required this.documentId,
    this.qrData,
    this.qrLocked = false,
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

  String? currentQrData;
  Offset? qrPosition;
  int? qrPageNumber;
  late bool qrLocked;
  bool _isProcessing = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    qrLocked = widget.qrLocked;
    if (widget.qrData != null) {
      _initializeQrFromData(widget.qrData!);
    }
  }

  void _initializeQrFromData(Map<String, dynamic> qrData) {
    if (mounted) {
      setState(() {
        currentQrData = qrData['sign_token'];
        qrPageNumber = qrData['selected_page'] ?? 1;
        qrPosition = Offset(
          MediaQuery.of(context).size.width / 2 -
              PdfViewerPage.qrDisplaySize / 2,
          MediaQuery.of(context).size.height / 2 -
              PdfViewerPage.qrDisplaySize / 2,
        );
      });
    }
  }

  Future<void> _safePdfOperation(Function operation) async {
    if (!mounted) return;

    setState(() => _isProcessing = true);
    try {
      await operation();
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
            child: qrLocked ? _buildSendButton() : _buildBackButton(),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildBackButton(),
        Container(
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
        ),
      ],
    );
  }

  Future<void> _sendDocument() async {
    try {
      if (!mounted) return;
      setState(() => _isSending = true);

      // 1. Persiapan token
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      if (authToken == null) throw Exception('Token tidak valid');

      // 2. Cek keberadaan file
      final file = File(widget.filePath);
      if (!await file.exists()) throw Exception('File tidak ditemukan');

      // 3. Membuat request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/documents/replace/${widget.documentId}'),
      );

      // 4. Menambahkan headers dan file
      request.headers['Authorization'] = 'Bearer $authToken';
      request.files.add(
        await http.MultipartFile.fromPath(
          'new_file',
          file.path,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      // 5. Mengirim request
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Berhasil
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Dokumen berhasil dikirim!')),
        );

        // Navigasi ke home
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
      if (!mounted) return;
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
              (route) => false,
            );
          }
        });
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
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.filePath);
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) {
              if (currentQrData != null && !qrLocked) {
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
                  if (mounted) {
                    setState(() {
                      qrPosition = newPosition;
                      qrPageNumber = pdfViewerController.pageNumber;
                    });
                  }
                }
              }
            },
            child: SfPdfViewer.file(
              file,
              key: _pdfViewerKey,
              controller: pdfViewerController,
            ),
          ),
          if (qrPosition != null && currentQrData != null && !qrLocked)
            Positioned(
              left: qrPosition!.dx,
              top: qrPosition!.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  final pdfViewerSize =
                      _pdfViewerKey.currentContext?.size ?? Size.zero;
                  final newPosition = Offset(
                    qrPosition!.dx + details.delta.dx,
                    qrPosition!.dy + details.delta.dy,
                  );

                  if (_isValidPosition(newPosition, pdfViewerSize)) {
                    if (mounted) {
                      setState(() => qrPosition = newPosition);
                    }
                  }
                },
                child: Container(
                  width: PdfViewerPage.qrDisplaySize,
                  height: PdfViewerPage.qrDisplaySize,
                  color: Colors.white,
                  child: QrImageView(
                    data: "${baseUrl}/$currentQrData",
                    version: QrVersions.auto,
                    size: PdfViewerPage.qrDisplaySize,
                    padding: const EdgeInsets.all(5.0),
                  ),
                ),
              ),
            ),
          _buildBottomNavigation(),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: currentQrData != null && !qrLocked
            ? FloatingActionButton.extended(
                backgroundColor: Colors.white,
                onPressed: () => _safePdfOperation(() async {
                  scaffoldMessengerKey.currentState?.showSnackBar(
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

                  if (mounted) {
                    setState(() {
                      qrLocked = true;
                      currentQrData = null;
                      qrPosition = null;
                      qrPageNumber = null;
                    });
                  }

                  scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'QR berhasil disimpan! Sekarang Anda bisa mengirim dokumen.',
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                label: const Text(
                  'Simpan QR',
                  style: TextStyle(color: Colors.black),
                ),
                icon: const Icon(Icons.save, color: Colors.black),
              )
            : FloatingActionButton.extended(
                backgroundColor: Colors.white,
                onPressed: _isProcessing
                    ? null
                    : () async {
                        if (currentQrData != null && !qrLocked) {
                          scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Selesaikan penempatan QR sebelumnya.',
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
                          documentId: widget.documentId,
                        );

                        if (result != null && result['sign_token'] != null) {
                          _initializeQrFromData(result);
                          scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'QR Code telah muncul. Geser untuk memposisikan.',
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
                icon: const Icon(Icons.edit, color: Colors.black),
              ),
      ),
    );
  }

  Future<void> insertQrToPdfDirectly({
    required String data,
    required int page,
    required Offset offset,
  }) async {
    final fileBytes = await File(widget.filePath).readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: fileBytes);

    final QrPainter qrPainter = QrPainter.withQr(
      qr: QrValidator.validate(
        data: "${baseUrl}/$data",
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      ).qrCode!,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );

    final ui.Image qrImage = await qrPainter.toImage(PdfViewerPage.qrPdfSize);
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

    final RenderBox pdfViewerRenderBox =
        _pdfViewerKey.currentContext!.findRenderObject() as RenderBox;
    final Size pdfViewerSize = pdfViewerRenderBox.size;

    final double zoomLevel = pdfViewerController.zoomLevel;
    final Offset scrollOffset = pdfViewerController.scrollOffset;

    final double pdfPageWidthInViewer = pdfPage.size.width / zoomLevel;
    final double pdfPageHeightInViewer = pdfPage.size.height / zoomLevel;

    final double pdfX =
        (offset.dx + scrollOffset.dx) *
        (pdfPage.size.width / pdfPageWidthInViewer);
    final double pdfY =
        (offset.dy + scrollOffset.dy) *
        (pdfPage.size.height / pdfPageHeightInViewer);

    final double qrSizeInPdf =
        PdfViewerPage.qrPdfSize * (pdfPage.size.width / pdfPageWidthInViewer);
    final double adjustedX = pdfX.clamp(0, pdfPage.size.width - qrSizeInPdf);
    final double adjustedY = pdfY.clamp(0, pdfPage.size.height - qrSizeInPdf);

    pdfPage.graphics.drawImage(
      pdfImage,
      Rect.fromLTWH(adjustedX, adjustedY, qrSizeInPdf, qrSizeInPdf),
    );

    final String outputPath =
        '${widget.filePath.substring(0, widget.filePath.lastIndexOf('.'))}_signed.pdf';
    final File newFile = File(outputPath);
    await newFile.writeAsBytes(await document.save());
    document.dispose();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(
            filePath: outputPath,
            documentId: widget.documentId,
            qrLocked: true, // Maintain the locked status
          ),
        ),
      );
    }
  }
}
