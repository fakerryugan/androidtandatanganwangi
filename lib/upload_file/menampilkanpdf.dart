// // // import 'dart:io';
// // // import 'dart:typed_data';
// // // import 'dart:ui' as ui;
// // // import 'package:flutter/material.dart';
// // // import 'package:syncfusion_flutter_pdf/pdf.dart';
// // // import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// // // import 'package:qr_flutter/qr_flutter.dart';
// // // import 'package:shared_preferences/shared_preferences.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:http_parser/http_parser.dart';
// // // import 'dart:convert';
// // //
// // // import '../api/token.dart';
// // // import 'package:android/upload_file/generateqr.dart';
// // // import 'package:android/upload_file/resizeqr.dart';
// // // import 'package:android/bottom_navbar/bottom_navbar.dart';
// // //
// // // /// Global ScaffoldMessenger untuk notifikasi
// // // final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();
// // //
// // // class PdfViewerPage extends StatefulWidget {
// // //   final String filePath;
// // //   final int documentId;
// // //   final Map<String, dynamic>? qrData;
// // //
// // //   const PdfViewerPage({
// // //     Key? key,
// // //     required this.filePath,
// // //     required this.documentId,
// // //     this.qrData,
// // //   }) : super(key: key);
// // //
// // //   @override
// // //   State<PdfViewerPage> createState() => _PdfViewerPageState();
// // // }
// // //
// // // class _PdfViewerPageState extends State<PdfViewerPage> {
// // //   final PdfViewerController _pdfViewerController = PdfViewerController();
// // //   final TextEditingController nipController = TextEditingController();
// // //   final TextEditingController tujuanController = TextEditingController();
// // //   final _formKey = GlobalKey<FormState>();
// // //
// // //   final GlobalKey<SfPdfViewerState> _pdfViewerKey =
// // //   GlobalKey<SfPdfViewerState>();
// // //
// // //   final ValueNotifier<Map<String, dynamic>?> _activeQrNotifier = ValueNotifier(null);
// // //   List<Map<String, dynamic>> qrCodes = [];
// // //   bool _isProcessing = false;
// // //   bool _isSending = false;
// // //   late String _currentPdfPath;
// // //
// // //   // ✅ ukuran default QR
// // //   static const double _initialQrSize = 100.0;
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _currentPdfPath = widget.filePath;
// // //
// // //     if (widget.qrData != null) {
// // //       WidgetsBinding.instance.addPostFrameCallback((_) {
// // //         final viewSize = MediaQuery.of(context).size;
// // //         setState(() {
// // //           qrCodes.add({
// // //             ...widget.qrData!,
// // //             'position': Offset(
// // //               viewSize.width / 2 - _initialQrSize / 2,
// // //               viewSize.height / 2 - _initialQrSize / 2,
// // //             ),
// // //             'size': _initialQrSize,
// // //             'locked': true,
// // //           });
// // //         });
// // //       });
// // //     }
// // //   }
// // //
// // //   // =====================================================
// // //   // Generate QR → Uint8List
// // //   // =====================================================
// // //   Future<Uint8List> _generateQrCodeBytes(String data,
// // //       {double size = 100.0}) async {
// // //     final painter = QrPainter(
// // //       data: data,
// // //       version: QrVersions.auto,
// // //       gapless: true,
// // //       color: Colors.black,
// // //       emptyColor: Colors.white,
// // //     );
// // //     final uiImage = await painter.toImage(size);
// // //     final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
// // //     return byteData!.buffer.asUint8List();
// // //   }
// // //
// // //   // =====================================================
// // //   // Simpan QR ke PDF
// // //   // =====================================================
// // //   Future<void> _saveAllQrCodesToPdf(dynamic pdfViewerController) async {
// // //     if (_isProcessing) return;
// // //     setState(() => _isProcessing = true);
// // //
// // //     try {
// // //       final scaffold = scaffoldMessengerKey.currentState;
// // //       scaffold?.showSnackBar(
// // //         const SnackBar(content: Text('Menyimpan QR ke PDF...')),
// // //       );
// // //
// // //       final originalFileBytes = await File(widget.filePath).readAsBytes();
// // //       final PdfDocument document = PdfDocument(inputBytes: originalFileBytes);
// // //
// // //       final qrCodesToSave = qrCodes.where((q) => q['locked'] != true).toList();
// // //
// // //       if (qrCodesToSave.isEmpty) {
// // //         scaffold?.showSnackBar(
// // //           const SnackBar(content: Text('Tidak ada QR yang perlu disimpan')),
// // //         );
// // //         return;
// // //       }
// // //
// // //       // for (final qr in unlockedQrs) {
// // //       //   // ✅ Ambil ukuran QR sesuai drag-resize (fallback ke _initialQrSize)
// // //       //   final double qrSize = (qr['size'] ?? _initialQrSize).toDouble();
// // //       //
// // //       //   final qrPainter = QrPainter.withQr(
// // //       //     qr: QrValidator.validate(
// // //       //       data: "$baseUrl/view/${qr['sign_token']}",
// // //       //       version: QrVersions.auto,
// // //       //       errorCorrectionLevel: QrErrorCorrectLevel.H,
// // //       //     ).qrCode!,
// // //       //     gapless: true,
// // //       //     color: const Color(0xFF000000),
// // //       //     emptyColor: const Color(0xFFFFFFFF), // background putih biar kontras
// // //       //   );
// // //       //
// // //       //   // ✅ Render QR dengan resolusi tinggi (×4 dari ukuran asli)
// // //       //   final ui.Image qrImage = await qrPainter.toImage((qrSize * 4));
// // //       //   final ByteData? byteData =
// // //       //   await qrImage.toByteData(format: ui.ImageByteFormat.png);
// // //       //   if (byteData == null) continue;
// // //       //
// // //       //   final Uint8List bytes = byteData.buffer.asUint8List();
// // //       //   final PdfBitmap pdfImage = PdfBitmap(bytes);
// // //       //
// // //       //   final int pageIndex = (qr['selected_page'] ?? 1) - 1;
// // //       //   if (pageIndex < 0 || pageIndex >= document.pages.count) continue;
// // //       //
// // //       //   final PdfPage pdfPage = document.pages[pageIndex];
// // //       //   final Offset position = qr['position'] ?? Offset.zero;
// // //       //
// // //       //   // ✅ Ambil ukuran halaman PDF & ukuran viewer
// // //       //   final Size pageSize = pdfPage.size;
// // //       //   final Size viewSize = _pdfViewerKey.currentContext?.size ?? Size.zero;
// // //       //   final double zoomLevel = pdfViewerController.zoomLevel;
// // //       //
// // //       //   // ✅ Hitung scaling (anggap proporsional, pakai scaleX saja)
// // //       //   final double scaleX = pageSize.width / (viewSize.width * zoomLevel);
// // //       //   final double scaleY = pageSize.height / (viewSize.height * zoomLevel);
// // //       //
// // //       //   // ✅ Mapping ke koordinat PDF
// // //       //   // var pdfX = position.dx * scaleX;
// // //       //   // var qrSizeInPdf = qrSize * scaleX;
// // //       //   // var pdfY = pageSize.height - (position.dy * scaleY) - qrSizeInPdf;
// // //
// // //
// // //       for (final qr in qrCodesToSave) {
// // //         if (qr['locked'] == false) {
// // //           final int pageIndex = (qr['selected_page'] as int) - 1;
// // //           final PdfPage pdfPage = document.pages[pageIndex];
// // //           final Offset position = qr['position'] as Offset;
// // //           final double qrSize = qr['size'] as double;
// // //           final String signToken = qr['sign_token'] as String;
// // //
// // //           final imageBytes = await QrPainter(
// // //             data: signToken,
// // //             version: QrVersions.auto,
// // //             gapless: true,
// // //           ).toImageData(1024); // Ukuran gambar resolusi tinggi
// // //
// // //
// // //           if (imageBytes != null) {
// // //             final pdfImage = PdfBitmap(imageBytes.buffer.asUint8List());
// // //             final Size pageSize = pdfPage.size;
// // //             final Size viewSize = _pdfViewerKey.currentContext?.size ?? Size.zero;
// // //
// // //             // ========================================================
// // //             // ✅ PERBAIKAN FINAL (REVISI): Kembali ke Logika Intuitif
// // //             // ========================================================
// // //
// // //
// // //             final Offset scrollOffset = _pdfViewerController.scrollOffset;
// // //
// // // // 2. Hitung padding internal (letterboxing/pillarboxing) yang diterapkan oleh SfPdfViewer.
// // //             final double viewAspectRatio = viewSize.width / viewSize.height;
// // //             final double pageAspectRatio = pageSize.width / pageSize.height;
// // //             double internalPaddingX = 0;
// // //             double internalPaddingY = 0;
// // //             double effectiveViewWidth;
// // //
// // //             if (pageAspectRatio > viewAspectRatio) {
// // //               // Pillarbox (padding atas/bawah)
// // //               effectiveViewWidth = viewSize.width;
// // //               final double effectiveViewHeight = effectiveViewWidth / pageAspectRatio;
// // //               internalPaddingY = (viewSize.height - effectiveViewHeight) / 2;
// // //             } else {
// // //               // Letterbox (padding kiri/kanan)
// // //               final double effectiveViewHeight = viewSize.height;
// // //               effectiveViewWidth = effectiveViewHeight * pageAspectRatio;
// // //               internalPaddingX = (viewSize.width - effectiveViewWidth) / 2;
// // //             }
// // //
// // // // 3. Hitung skala yang benar berdasarkan lebar efektif PDF yang terlihat.
// // //             final double scale = pageSize.width / effectiveViewWidth;
// // //
// // // // 4. Hitung posisi PUSAT QR di layar.
// // //             final Offset qrCenterOnScreen = Offset(
// // //               position.dx + (qrSize / 2),
// // //               position.dy + (qrSize / 2),
// // //             );
// // //
// // // // 5. Hitung posisi mentah (raw position) dari PUSAT QR,
// // // //    DENGAN MENGURANGI PADDING INTERNAL untuk mendapatkan posisi yang benar
// // // //    relatif terhadap PDF yang terlihat.
// // //             final double rawCenterX = (qrCenterOnScreen.dx - internalPaddingX) + scrollOffset.dx;
// // //             final double rawCenterY = (qrCenterOnScreen.dy - internalPaddingY) + scrollOffset.dy;
// // //
// // // // 6. Konversi posisi PUSAT dan ukuran ke unit PDF menggunakan skala yang akurat.
// // //             double pdfCenterX = rawCenterX * scale;
// // //             double qrSizeInPdf = qrSize * scale;
// // //
// // // // 7. Konversi sumbu Y untuk PUSAT QR.
// // //             double pdfCenterY = pageSize.height - (rawCenterY * scale);
// // //
// // // // 8. Hitung posisi pojok kiri-atas (x, y) dari pusat QR di koordinat PDF.
// // //             double pdfX = pdfCenterX - (qrSizeInPdf / 2);
// // //             double pdfY = pdfCenterY - (qrSizeInPdf / 2);
// // //
// // // // 9. Clamp (batasi) nilai agar tidak keluar dari halaman.
// // //             pdfX = pdfX.clamp(0, pageSize.width - qrSizeInPdf);
// // //             pdfY = pdfY.clamp(0, pageSize.height - qrSizeInPdf);
// // //
// // // // Debug log untuk verifikasi
// // //             debugPrint("=== QR Mapping (PADDING CORRECTED) ===");
// // //             debugPrint("Internal Padding: x=${internalPaddingX.toStringAsFixed(2)}, y=${internalPaddingY.toStringAsFixed(2)}");
// // //             debugPrint("Scale (Corrected): ${scale.toStringAsFixed(4)}");
// // //             debugPrint("Final PDF Top-Left: x=${pdfX.toStringAsFixed(2)}, y=${pdfY.toStringAsFixed(2)}, size=${qrSizeInPdf.toStringAsFixed(2)}");
// // //             debugPrint("======================================");
// // //
// // // // Gambar QR ke PDF menggunakan koordinat pojok kiri-atas yang sudah benar.
// // //             pdfPage.graphics.drawImage(
// // //               pdfImage,
// // //               Rect.fromLTWH(pdfX, pdfY, qrSizeInPdf, qrSizeInPdf),
// // //             );
// // //             // ========================================================
// // //             // ✅ AKHIR DARI BLOK PERBAIKAN
// // //             // ========================================================
// // //           }
// // //         }
// // //       }
// // //
// // //         final tempPath =
// // //             '${Directory.systemTemp.path}/temp_${DateTime
// // //             .now()
// // //             .millisecondsSinceEpoch}.pdf';
// // //         await File(tempPath).writeAsBytes(await document.save());
// // //         document.dispose();
// // //
// // //         await File(_currentPdfPath).delete();
// // //         await File(tempPath).rename(_currentPdfPath);
// // //
// // //         setState(() {
// // //           qrCodes = qrCodes.map((qr) => {...qr, 'locked': true}).toList();
// // //         });
// // //
// // //         scaffold?.showSnackBar(
// // //           const SnackBar(content: Text('QR berhasil disimpan!')),
// // //         );
// // //       } catch (e) {
// // //       scaffoldMessengerKey.currentState?.showSnackBar(
// // //         SnackBar(content: Text('Error: ${e.toString()}')),
// // //       );
// // //     } finally {
// // //       if (mounted) setState(() => _isProcessing = false);
// // //     }
// // //   }
// // //
// // //
// // //   // =====================================================
// // //   // UI
// // //   // =====================================================
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final unlockedQr = qrCodes.where((q) => q['locked'] == false).toList();
// // //     final bool hasUnlockedQr = unlockedQr.isNotEmpty;
// // //
// // //     return Scaffold(
// // //       appBar: _buildAppBar(),
// // //       body: LayoutBuilder(
// // //         builder: (context, constraints) {
// // //           return Stack(
// // //             children: [
// // //               GestureDetector(
// // //                 onTapDown: (details) {
// // //                   if (hasUnlockedQr) {
// // //                     final qrToMove = unlockedQr.first;
// // //                     final newPosition = details.localPosition -
// // //                         Offset(qrToMove['size'] / 2, qrToMove['size'] / 2);
// // //                     setState(() {
// // //                       final index = qrCodes.indexWhere(
// // //                               (q) => q['sign_token'] == qrToMove['sign_token']);
// // //                       if (index != -1) {
// // //                         qrCodes[index]['position'] = Offset(
// // //                           newPosition.dx.clamp(
// // //                               0, constraints.maxWidth - qrToMove['size']),
// // //                           newPosition.dy.clamp(
// // //                               0, constraints.maxHeight - qrToMove['size']),
// // //                         );
// // //                         qrCodes[index]['selected_page'] =
// // //                             _pdfViewerController.pageNumber;
// // //                       }
// // //                     });
// // //                   }
// // //                 },
// // //                 child: SfPdfViewer.file(
// // //                   File(_currentPdfPath),
// // //                   key: _pdfViewerKey,
// // //                   controller: _pdfViewerController,
// // //                 ),
// // //               ),
// // //               ...unlockedQr.map((qr) {
// // //                 final index = qrCodes
// // //                     .indexWhere((q) => q['sign_token'] == qr['sign_token']);
// // //                 return ResizableQrCode(
// // //                   key: ValueKey(qr['sign_token']),
// // //                   constraints: constraints,
// // //                   qrData: qr,
// // //                   onDragUpdate: (newPosition) {
// // //                     qrCodes[index]['position'] = newPosition;
// // //                   },
// // //                   onResizeUpdate: (newSize) {
// // //                     qrCodes[index]['size'] = newSize;
// // //                   },
// // //                   onDragEnd: () {
// // //                     setState(() {
// // //                       qrCodes[index]['selected_page'] =
// // //                           _pdfViewerController.pageNumber;
// // //                     });
// // //                   },
// // //                 );
// // //               }).toList(),
// // //               _buildBottomNavigation(hasUnlockedQr),
// // //               if (_isProcessing) const Center(child: CircularProgressIndicator()),
// // //             ],
// // //           );
// // //         },
// // //       ),
// // //       floatingActionButton: Visibility(
// // //         visible: !_isProcessing && (!_isSending),
// // //         child: Padding(
// // //           padding: const EdgeInsets.only(bottom: 70.0),
// // //           child: FloatingActionButton.extended(
// // //             backgroundColor: Colors.white,
// // //             onPressed: () async {
// // //               if (qrCodes.where((q) => q['locked'] == false).isNotEmpty) {
// // //                 // PANGGIL FUNGSI DENGAN TANDA KURUNG DAN ARGUMEN
// // //                 await _saveAllQrCodesToPdf(_pdfViewerController);
// // //                 // `setState` setelahnya tidak lagi diperlukan di sini,
// // //                 // karena sudah diatur di dalam _saveAllQrCodesToPdf
// // //               } else {
// // //                 _addNewQrCode();
// // //               }
// // //             },
// // //             shape: RoundedRectangleBorder(
// // //               borderRadius: BorderRadius.circular(20),
// // //               side: const BorderSide(color: Colors.black, width: 2),
// // //             ),
// // //             label: Text(
// // //               hasUnlockedQr ? 'Simpan Posisi QR' : '+ Tanda Tangan',
// // //               style: const TextStyle(color: Colors.black),
// // //             ),
// // //             icon: Icon(
// // //               hasUnlockedQr ? Icons.save : Icons.edit,
// // //               color: Colors.black,
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   AppBar _buildAppBar() {
// // //     return AppBar(
// // //       title: const Text('Edit & Tanda Tangan',
// // //           style: TextStyle(color: Colors.white)),
// // //       backgroundColor: const Color(0xFF172B4C),
// // //       centerTitle: true,
// // //       automaticallyImplyLeading: false,
// // //     );
// // //   }
// // //
// // //   Widget _buildBottomNavigation(bool hasUnlockedQr) {
// // //     return Align(
// // //       alignment: Alignment.bottomCenter,
// // //       child: ClipRRect(
// // //         borderRadius: const BorderRadius.only(
// // //           topLeft: Radius.circular(30),
// // //           topRight: Radius.circular(30),
// // //         ),
// // //         child: Container(
// // //           height: 60,
// // //           color: const Color(0xFF172B4C),
// // //           child: Row(
// // //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // //             children: [
// // //               _buildBackButton(),
// // //               if (!hasUnlockedQr && qrCodes.isNotEmpty) _buildSendButton(),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildBackButton() {
// // //     return Container(
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(15),
// // //       ),
// // //       child: IconButton(
// // //         icon: const Icon(Icons.arrow_back_outlined, color: Color(0xFF172B4C)),
// // //         onPressed: _showCancelConfirmationDialog,
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildSendButton() {
// // //     return Container(
// // //       decoration: BoxDecoration(
// // //         color: Colors.green,
// // //         borderRadius: BorderRadius.circular(15),
// // //       ),
// // //       child: _isSending
// // //           ? const Padding(
// // //         padding: EdgeInsets.all(8.0),
// // //         child: CircularProgressIndicator(color: Colors.white),
// // //       )
// // //           : IconButton(
// // //         icon: const Icon(Icons.send, color: Colors.white),
// // //         onPressed: _sendDocument,
// // //       ),
// // //     );
// // //   }
// // //
// // //   // =====================================================
// // //   // Tambah QR
// // //   // =====================================================
// // //   void _addNewQrCode() async {
// // //     final result = await showInputDialog(
// // //       context: context,
// // //       formKey: _formKey,
// // //       nipController: nipController,
// // //       tujuanController: tujuanController,
// // //       showTujuan: true,
// // //       totalPages: _pdfViewerController.pageCount,
// // //       documentId: widget.documentId,
// // //     );
// // //     if (result != null && result['sign_token'] != null) {
// // //       final viewSize = MediaQuery.of(context).size;
// // //       setState(() {
// // //         qrCodes.add({
// // //           'sign_token': result['sign_token'],
// // //           'selected_page': result['selected_page'],
// // //           'position': Offset(
// // //             viewSize.width / 2 - _initialQrSize / 2,
// // //             viewSize.height / 2 - _initialQrSize / 2,
// // //           ),
// // //           'size': _initialQrSize,
// // //           'locked': false,
// // //         });
// // //       });
// // //     }
// // //   }
// // //
// // //   // =====================================================
// // //   // Kirim dokumen
// // //   // =====================================================
// // //   Future<void> _sendDocument() async {
// // //     try {
// // //       setState(() => _isSending = true);
// // //       final prefs = await SharedPreferences.getInstance();
// // //       final authToken = prefs.getString('token');
// // //       if (authToken == null) throw Exception('Token tidak valid');
// // //
// // //       var request = http.MultipartRequest(
// // //         'POST',
// // //         Uri.parse('$baseUrl/documents/replace/${widget.documentId}'),
// // //       );
// // //       request.headers['Authorization'] = 'Bearer $authToken';
// // //       request.files.add(
// // //         await http.MultipartFile.fromPath(
// // //           'pdf', // ✅ tanpa spasi
// // //           _currentPdfPath,
// // //           contentType: MediaType('application', 'pdf'),
// // //         ),
// // //       );
// // //
// // //       var response = await request.send();
// // //       var responseBody = await response.stream.bytesToString();
// // //
// // //       if (response.statusCode == 200) {
// // //         scaffoldMessengerKey.currentState?.showSnackBar(
// // //           const SnackBar(content: Text('Dokumen berhasil dikirim!')),
// // //         );
// // //         if (mounted) {
// // //           Navigator.pushAndRemoveUntil(
// // //             context,
// // //             MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
// // //                 (route) => false,
// // //           );
// // //         }
// // //       } else {
// // //         throw Exception(
// // //           jsonDecode(responseBody)['message'] ?? 'Gagal mengirim dokumen',
// // //         );
// // //       }
// // //     } catch (e) {
// // //       scaffoldMessengerKey.currentState?.showSnackBar(
// // //         SnackBar(content: Text('Error: ${e.toString()}')),
// // //       );
// // //     } finally {
// // //       if (mounted) setState(() => _isSending = false);
// // //     }
// // //   }
// // //
// // //   // =====================================================
// // //   // Batalkan dokumen
// // //   // =====================================================
// // //   Future<void> _showCancelConfirmationDialog() async {
// // //     await showDialog(
// // //       context: context,
// // //       builder: (context) => AlertDialog(
// // //         title: const Text('Batalkan Dokumen'),
// // //         content: const Text(
// // //           'Apakah Anda yakin ingin membatalkan dokumen ini?',
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.of(context).pop(),
// // //             child: const Text('Tidak'),
// // //           ),
// // //           TextButton(
// // //             onPressed: _isProcessing
// // //                 ? null
// // //                 : () async {
// // //               Navigator.of(context).pop();
// // //               await _cancelDocumentRequest();
// // //             },
// // //             child: _isProcessing
// // //                 ? const SizedBox(
// // //               width: 20,
// // //               height: 20,
// // //               child: CircularProgressIndicator(strokeWidth: 2),
// // //             )
// // //                 : const Text('Ya, Batalkan'),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //
// // //   Future<void> _cancelDocumentRequest() async {
// // //     try {
// // //       setState(() => _isProcessing = true);
// // //       final response = await cancelDocument(widget.documentId);
// // //
// // //       if (response['success'] == true) {
// // //         final prefs = await SharedPreferences.getInstance();
// // //         await prefs.remove('document_id');
// // //
// // //         scaffoldMessengerKey.currentState?.showSnackBar(
// // //           SnackBar(content: Text(response['message'] ?? 'Dokumen dibatalkan')),
// // //         );
// // //         if (mounted) {
// // //           Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
// // //             MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
// // //                 (route) => false,
// // //           );
// // //         }
// // //       } else {
// // //         scaffoldMessengerKey.currentState?.showSnackBar(
// // //           SnackBar(content: Text(response['message'] ?? 'Gagal membatalkan')),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       scaffoldMessengerKey.currentState?.showSnackBar(
// // //         SnackBar(content: Text('Error: ${e.toString()}')),
// // //       );
// // //     } finally {
// // //       if (mounted) setState(() => _isProcessing = false);
// // //     }
// // //   }
// // // }
// //
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

  // ✅ BARU: ValueNotifier untuk mengelola QR yang sedang aktif.
  final ValueNotifier<Map<String, dynamic>?> _activeQrNotifier = ValueNotifier(null);

  List<Map<String, dynamic>> qrCodes = [];
  bool _isProcessing = false;
  bool _isSending = false;
  late String _currentPdfPath;

  static const double _initialQrSize = 100.0;

  @override
  void initState() {
    super.initState();
    _currentPdfPath = widget.filePath;

    if (widget.qrData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final viewSize = MediaQuery.of(context).size;

        // Langsung jadikan QR yang ada sebagai QR AKTIF, bukan dikunci.
        _activeQrNotifier.value = {
          ...widget.qrData!,
          'position': Offset(
            viewSize.width / 2 - _initialQrSize / 2, // Mulai dari tengah layar
            viewSize.height / 2 - _initialQrSize / 2,
          ),
          'size': _initialQrSize,
          'locked': false, // <-- PENTING: ini membuatnya bisa digerakkan
        };
      });
    }
  }

  // =====================================================
  // Generate QR → Uint8List (Tidak berubah)
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
  // Simpan QR ke PDF (Tidak berubah)
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

      // Logika ini tetap valid, karena saat fungsi ini dipanggil, QR yang aktif
      // sudah dimasukkan ke dalam list `qrCodes` dengan status `locked: false`.
      final qrCodesToSave = qrCodes.where((q) => q['locked'] != true).toList();

      if (qrCodesToSave.isEmpty) {
        scaffold?.showSnackBar(
          const SnackBar(content: Text('Tidak ada QR yang perlu disimpan')),
        );
        return;
      }

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
          ).toImageData(1024);


          if (imageBytes != null) {
            final pdfImage = PdfBitmap(imageBytes.buffer.asUint8List());
            final Size pageSize = pdfPage.size;
            final Size viewSize = _pdfViewerKey.currentContext?.size ?? Size.zero;

            final Offset scrollOffset = _pdfViewerController.scrollOffset;

            final double viewAspectRatio = viewSize.width / viewSize.height;
            final double pageAspectRatio = pageSize.width / pageSize.height;
            double internalPaddingX = 0;
            double internalPaddingY = 0;
            double effectiveViewWidth;

            if (pageAspectRatio > viewAspectRatio) {
              effectiveViewWidth = viewSize.width;
              final double effectiveViewHeight = effectiveViewWidth / pageAspectRatio;
              internalPaddingY = (viewSize.height - effectiveViewHeight) / 2;
            } else {
              final double effectiveViewHeight = viewSize.height;
              effectiveViewWidth = effectiveViewHeight * pageAspectRatio;
              internalPaddingX = (viewSize.width - effectiveViewWidth) / 2;
            }

            final double scale = pageSize.width / effectiveViewWidth;
            final Offset qrCenterOnScreen = Offset(position.dx + (qrSize / 2), position.dy + (qrSize / 2));
            // ✅ PERBAIKAN FINAL: Hapus scrollOffset.dx karena sudah diperhitungkan oleh padding
            final double rawCenterX = (qrCenterOnScreen.dx - internalPaddingX);
            final double rawCenterY = (qrCenterOnScreen.dy - internalPaddingY) + scrollOffset.dy;
            double pdfCenterX = rawCenterX * scale;
            double qrSizeInPdf = qrSize * scale;
            double pdfCenterY = pageSize.height - (rawCenterY * scale);
            double pdfX = pdfCenterX - (qrSizeInPdf / 2);
            double pdfY = pdfCenterY - (qrSizeInPdf / 2);

            pdfX = pdfX.clamp(0, pageSize.width - qrSizeInPdf);
            pdfY = pdfY.clamp(0, pageSize.height - qrSizeInPdf);

            debugPrint("=== QR Mapping (PADDING CORRECTED) ===");
            debugPrint("Internal Padding: x=${internalPaddingX.toStringAsFixed(2)}, y=${internalPaddingY.toStringAsFixed(2)}");
            debugPrint("Scale (Corrected): ${scale.toStringAsFixed(4)}");
            debugPrint("Final PDF Top-Left: x=${pdfX.toStringAsFixed(2)}, y=${pdfY.toStringAsFixed(2)}, size=${qrSizeInPdf.toStringAsFixed(2)}");
            debugPrint("======================================");

            pdfPage.graphics.drawImage(
              pdfImage,
              Rect.fromLTWH(pdfX, pdfY, qrSizeInPdf, qrSizeInPdf),
            );
          }
        }
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

  // =====================================================
  // ✅ UI (DIREFAKTOR TOTAL)
  // =====================================================
  @override
  Widget build(BuildContext context) {
    // Dapatkan status dari notifier untuk logika UI
    final bool hasActiveQr = _activeQrNotifier.value != null;

    return Scaffold(
      key: scaffoldMessengerKey, // Pasang key di Scaffold
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              GestureDetector(
                // LOGIKA TAPDOWN YANG STABIL
                onTapDown: (details) {
                  // Hanya bekerja jika ada QR yang sedang aktif
                  if (_activeQrNotifier.value != null) {
                    final qrToMove = _activeQrNotifier.value!;
                    final double qrSize = qrToMove['size'] as double;

                    // Hitung posisi baru (pusat QR di titik sentuh)
                    final newPosition = details.localPosition - Offset(qrSize / 2, qrSize / 2);

                    // HANYA UPDATE NOTIFIER, BUKAN setState(). Ini sangat cepat.
                    _activeQrNotifier.value = {
                      ...qrToMove,
                      'position': Offset(
                        newPosition.dx.clamp(0, constraints.maxWidth - qrSize),
                        newPosition.dy.clamp(0, constraints.maxHeight - qrSize),
                      ),
                      'selected_page': _pdfViewerController.pageNumber,
                    };
                  }
                },
                child: SfPdfViewer.file(
                  File(_currentPdfPath),
                  key: _pdfViewerKey,
                  controller: _pdfViewerController,
                ),
              ),

              // RENDER QR YANG TERKUNCI (sudah disimpan) DARI DAFTAR UTAMA
              for (final qrData in qrCodes.where((q) => q['locked'] == true))
                Positioned(
                  left: (qrData['position'] as Offset).dx,
                  top: (qrData['position'] as Offset).dy,
                  child: SizedBox(
                      width: qrData['size'],
                      height: qrData['size'],
                      child: QrImageView(data: qrData['sign_token'])),
                ),

              // RENDER QR AKTIF MENGGUNAKAN ValueListenableBuilder
              ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: _activeQrNotifier,
                builder: (context, activeQr, child) {
                  if (activeQr == null) {
                    return const SizedBox.shrink(); // Tidak ada QR aktif
                  }
                  return ResizableQrCode(
                    key: ValueKey('resizable_qr_${activeQr['sign_token']}'),
                    constraints: constraints,
                    qrData: activeQr,
                    onDragUpdate: (newPosition) {
                      _activeQrNotifier.value = {...activeQr, 'position': newPosition};
                    },
                    onResizeUpdate: (newSize) {
                      _activeQrNotifier.value = {...activeQr, 'size': newSize};
                    },
                    onDragEnd: () {
                      final updatedQr = _activeQrNotifier.value!;
                      _activeQrNotifier.value = {
                        ...updatedQr,
                        'selected_page': _pdfViewerController.pageNumber,
                      };
                    },
                  );
                },
              ),

              _buildBottomNavigation(hasActiveQr),
              if (_isProcessing) const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
      floatingActionButton: Visibility(
        visible: !_isProcessing && !_isSending,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 70.0),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.white,
            onPressed: _handleMainButtonAction, // Panggil fungsi baru
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            label: Text(
              hasActiveQr ? 'Tanda Tangan' : 'Simpan Posisi QR',
              style: const TextStyle(color: Colors.black),
            ),
            icon: Icon(
              hasActiveQr ? Icons.add : Icons.save, // Ganti ikon menjadi '+'
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Helper Widgets & Dialogs (Tidak berubah)
  // =====================================================
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Edit & Tanda Tangan', style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF172B4C),
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildBottomNavigation(bool hasActiveQr) {
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
              // Tombol kirim hanya muncul jika tidak ada QR aktif dan list QR tidak kosong
              if (!hasActiveQr && qrCodes.isNotEmpty) _buildSendButton(),
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
  // ✅ FUNGSI LOGIKA BARU
  // =====================================================

  /// Mengelola aksi tombol utama (tambah atau simpan QR).
  Future<void> _handleMainButtonAction() async {
    if (_activeQrNotifier.value != null) {
      // Jika ada QR aktif, SIMPAN
      final activeQr = _activeQrNotifier.value!;

      // 1. Finalisasi posisi QR dari notifier ke daftar utama
      setState(() {
        // JADIKAN QR AKTIF SEBAGAI SATU-SATUNYA ITEM DI DALAM DAFTAR
        // Ini akan menghapus semua QR lama secara total.
        qrCodes = [activeQr];

        // Kosongkan notifier untuk menyembunyikan QR aktif
        _activeQrNotifier.value = null;
      });

      // 2. Beri jeda singkat agar UI sempat update sebelum proses berat
      await Future.delayed(const Duration(milliseconds: 50));

      // 3. Panggil fungsi save yang berisi logika kalkulasi Anda
      await _saveAllQrCodesToPdf(_pdfViewerController);
    } else {
      // Jika tidak ada QR aktif, TAMBAH BARU
      _addNewQrCode();
    }
  }

  /// Menampilkan dialog dan membuat QR baru sebagai QR aktif.
  void _addNewQrCode() async {
    // Hanya izinkan satu QR aktif pada satu waktu
    if (_activeQrNotifier.value != null) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Selesaikan atau simpan tanda tangan yang ada terlebih dahulu.')),
      );
      return;
    }

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
      final newQr = {
        'sign_token': result['sign_token'],
        'selected_page': result['selected_page'],
        'position': Offset(
          viewSize.width / 2 - _initialQrSize / 2,
          viewSize.height / 2 - _initialQrSize / 2,
        ),
        'size': _initialQrSize,
        'locked': false, // QR baru selalu tidak terkunci
      };

      // Set QR baru sebagai QR yang aktif via notifier
      _activeQrNotifier.value = newQr;
    }
  }

  // =====================================================
  // Logika Kirim & Batal (Tidak berubah)
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
//
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'dart:convert';
//
// import '../api/token.dart';
// import 'package:android/upload_file/generateqr.dart';
// import 'package:android/upload_file/resizeqr.dart';
// import 'package:android/bottom_navbar/bottom_navbar.dart';
//
// /// Global ScaffoldMessenger untuk notifikasi
// final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();
//
// class PdfViewerPage extends StatefulWidget {
//   final String filePath;
//   final int documentId;
//   final Map<String, dynamic>? qrData;
//
//   const PdfViewerPage({
//     Key? key,
//     required this.filePath,
//     required this.documentId,
//     this.qrData,
//   }) : super(key: key);
//
//   @override
//   State<PdfViewerPage> createState() => _PdfViewerPageState();
// }
//
// class _PdfViewerPageState extends State<PdfViewerPage> {
//   final PdfViewerController _pdfViewerController = PdfViewerController();
//   final TextEditingController nipController = TextEditingController();
//   final TextEditingController tujuanController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//
//   // ✅ [REVISI] Kita kembalikan GlobalKey ini untuk controller, bukan untuk ukuran
//   final GlobalKey<SfPdfViewerState> _pdfViewerStateKey = GlobalKey<SfPdfViewerState>();
//
//   final ValueNotifier<Map<String, dynamic>?> _activeQrNotifier = ValueNotifier(null);
//   List<Map<String, dynamic>> qrCodes = [];
//   bool _isProcessing = false;
//   bool _isSending = false;
//   late String _currentPdfPath;
//
//   // ✅ [FIX] Variabel baru untuk menyimpan ukuran view PDF secara andal
//   Size? _pdfViewSize;
//
//   static const double _initialQrSize = 100.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _currentPdfPath = widget.filePath;
//
//     if (widget.qrData != null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         final viewSize = MediaQuery.of(context).size;
//         _activeQrNotifier.value = {
//           ...widget.qrData!,
//           'position': Offset(
//             viewSize.width / 2 - _initialQrSize / 2,
//             viewSize.height / 2 - _initialQrSize / 2,
//           ),
//           'size': _initialQrSize,
//           'locked': false,
//         };
//       });
//     }
//   }
//
//   // =====================================================
//   // Simpan QR ke PDF
//   // =====================================================
//   Future<void> _saveAllQrCodesToPdf(dynamic pdfViewerController) async {
//     if (_isProcessing) return;
//     setState(() => _isProcessing = true);
//
//     try {
//       final scaffold = scaffoldMessengerKey.currentState;
//
//       // ✅ [FIX] Gunakan variabel _pdfViewSize yang sudah disimpan
//       final Size? viewSize = _pdfViewSize;
//
//       if (viewSize == null || viewSize.isEmpty) {
//         scaffold?.showSnackBar(const SnackBar(content: Text('Gagal mendapatkan ukuran view. Coba lagi.')));
//         setState(() => _isProcessing = false); // Reset agar tidak loading terus
//         return;
//       }
//
//       scaffold?.showSnackBar(
//         const SnackBar(content: Text('Menyimpan QR ke PDF...')),
//       );
//
//       final originalFileBytes = await File(_currentPdfPath).readAsBytes();
//       final PdfDocument document = PdfDocument(inputBytes: originalFileBytes);
//
//       final qrCodesToSave = qrCodes.where((q) => q['locked'] != true).toList();
//
//       if (qrCodesToSave.isEmpty) {
//         // Jika tidak ada QR untuk disimpan, cukup hentikan proses
//         setState(() => _isProcessing = false);
//         return;
//       }
//
//       for (final qr in qrCodesToSave) {
//         final int pageIndex = (qr['selected_page'] as int) - 1;
//         final PdfPage pdfPage = document.pages[pageIndex];
//         final Offset position = qr['position'] as Offset;
//         final double qrSize = qr['size'] as double;
//         final String signToken = qr['sign_token'] as String;
//
//         final imageBytes = await QrPainter(
//           data: signToken,
//           version: QrVersions.auto,
//           gapless: true,
//         ).toImageData(1024);
//
//         if (imageBytes != null) {
//           final pdfImage = PdfBitmap(imageBytes.buffer.asUint8List());
//           final Size pageSize = pdfPage.size;
//           // Kita sudah punya viewSize dari atas
//           final Offset scrollOffset = _pdfViewerController.scrollOffset;
//           final double viewAspectRatio = viewSize.width / viewSize.height;
//           final double pageAspectRatio = pageSize.width / pageSize.height;
//           double internalPaddingX = 0;
//           double internalPaddingY = 0;
//           double effectiveViewWidth;
//
//           if (pageAspectRatio > viewAspectRatio) {
//             effectiveViewWidth = viewSize.width;
//             final double effectiveViewHeight = effectiveViewWidth / pageAspectRatio;
//             internalPaddingY = (viewSize.height - effectiveViewHeight) / 2;
//           } else {
//             final double effectiveViewHeight = viewSize.height;
//             effectiveViewWidth = effectiveViewHeight * pageAspectRatio;
//             internalPaddingX = (viewSize.width - effectiveViewWidth) / 2;
//           }
//
//           final double scale = pageSize.width / effectiveViewWidth;
//           final Offset qrCenterOnScreen = Offset(position.dx + (qrSize / 2), position.dy + (qrSize / 2));
//           final double rawCenterX = (qrCenterOnScreen.dx - internalPaddingX) + scrollOffset.dx;
//           final double rawCenterY = (qrCenterOnScreen.dy - internalPaddingY) + scrollOffset.dy;
//           double pdfCenterX = rawCenterX * scale;
//           double qrSizeInPdf = qrSize * scale;
//           double pdfCenterY = pageSize.height - (rawCenterY * scale);
//           double pdfX = pdfCenterX - (qrSizeInPdf / 2);
//           double pdfY = pdfCenterY - (qrSizeInPdf / 2);
//
//           pdfX = pdfX.clamp(0, pageSize.width - qrSizeInPdf);
//           pdfY = pdfY.clamp(0, pageSize.height - qrSizeInPdf);
//
//           pdfPage.graphics.drawImage(
//             pdfImage,
//             Rect.fromLTWH(pdfX, pdfY, qrSizeInPdf, qrSizeInPdf),
//           );
//         }
//       }
//
//       final tempPath = '${Directory.systemTemp.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf';
//       await File(tempPath).writeAsBytes(await document.save());
//       document.dispose();
//
//       await File(_currentPdfPath).delete();
//       await File(tempPath).rename(_currentPdfPath);
//
//       setState(() {
//         qrCodes = qrCodes.map((qr) => {...qr, 'locked': true}).toList();
//       });
//
//       scaffold?.showSnackBar(
//         const SnackBar(content: Text('QR berhasil disimpan!')),
//       );
//     } catch (e) {
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(content: Text('Error saat menyimpan: ${e.toString()}')),
//       );
//     } finally {
//       if (mounted) setState(() => _isProcessing = false);
//     }
//   }
//
//   // =====================================================
//   // UI
//   // =====================================================
//   @override
//   Widget build(BuildContext context) {
//     final bool hasActiveQr = _activeQrNotifier.value != null;
//
//     return Scaffold(
//       key: scaffoldMessengerKey,
//       appBar: _buildAppBar(),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           // ✅ [FIX] Simpan ukuran view dari LayoutBuilder di sini
//           _pdfViewSize = Size(constraints.maxWidth, constraints.maxHeight);
//
//           return Stack(
//             children: [
//               GestureDetector(
//                 onTapDown: (details) {
//                   if (_activeQrNotifier.value != null) {
//                     final qrToMove = _activeQrNotifier.value!;
//                     final double qrSize = qrToMove['size'] as double;
//                     final newPosition = details.localPosition - Offset(qrSize / 2, qrSize / 2);
//                     _activeQrNotifier.value = {
//                       ...qrToMove,
//                       'position': Offset(
//                         newPosition.dx.clamp(0, constraints.maxWidth - qrSize),
//                         newPosition.dy.clamp(0, constraints.maxHeight - qrSize),
//                       ),
//                       'selected_page': _pdfViewerController.pageNumber,
//                     };
//                   }
//                 },
//                 child: SfPdfViewer.file(
//                   File(_currentPdfPath),
//                   // ✅ [REVISI] Kembalikan GlobalKey ke widget
//                   key: _pdfViewerStateKey,
//                   controller: _pdfViewerController,
//                 ),
//               ),
//               for (final qrData in qrCodes.where((q) => q['locked'] == true))
//                 Positioned(
//                   left: (qrData['position'] as Offset).dx,
//                   top: (qrData['position'] as Offset).dy,
//                   child: SizedBox(
//                       width: qrData['size'],
//                       height: qrData['size'],
//                       child: QrImageView(data: qrData['sign_token'])),
//                 ),
//               ValueListenableBuilder<Map<String, dynamic>?>(
//                 valueListenable: _activeQrNotifier,
//                 builder: (context, activeQr, child) {
//                   if (activeQr == null) {
//                     return const SizedBox.shrink();
//                   }
//                   return ResizableQrCode(
//                     key: ValueKey('resizable_qr_${activeQr['sign_token']}'),
//                     constraints: constraints,
//                     qrData: activeQr,
//                     onDragUpdate: (newPosition) {
//                       _activeQrNotifier.value = {...activeQr, 'position': newPosition};
//                     },
//                     onResizeUpdate: (newSize) {
//                       _activeQrNotifier.value = {...activeQr, 'size': newSize};
//                     },
//                     onDragEnd: () {
//                       final updatedQr = _activeQrNotifier.value!;
//                       _activeQrNotifier.value = {
//                         ...updatedQr,
//                         'selected_page': _pdfViewerController.pageNumber,
//                       };
//                     },
//                   );
//                 },
//               ),
//               _buildBottomNavigation(hasActiveQr),
//               if (_isProcessing) const Center(child: CircularProgressIndicator()),
//             ],
//           );
//         },
//       ),
//       floatingActionButton: Visibility(
//         visible: !_isProcessing && !_isSending,
//         child: Padding(
//           padding: const EdgeInsets.only(bottom: 70.0),
//           child: FloatingActionButton.extended(
//             backgroundColor: Colors.white,
//             onPressed: _handleMainButtonAction,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//               side: const BorderSide(color: Colors.black, width: 2),
//             ),
//             label: Text(
//               hasActiveQr ? 'Simpan Posisi QR' : '+ Tanda Tangan',
//               style: const TextStyle(color: Colors.black),
//             ),
//             icon: Icon(
//               hasActiveQr ? Icons.save : Icons.add,
//               color: Colors.black,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   AppBar _buildAppBar() {
//     return AppBar(
//       title: const Text('Edit & Tanda Tangan', style: TextStyle(color: Colors.white)),
//       backgroundColor: const Color(0xFF172B4C),
//       centerTitle: true,
//       automaticallyImplyLeading: false,
//     );
//   }
//
//   Widget _buildBottomNavigation(bool hasActiveQr) {
//     return Align(
//       alignment: Alignment.bottomCenter,
//       child: ClipRRect(
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(30),
//           topRight: Radius.circular(30),
//         ),
//         child: Container(
//           height: 60,
//           color: const Color(0xFF172B4C),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildBackButton(),
//               if (!hasActiveQr && qrCodes.isNotEmpty) _buildSendButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBackButton() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: IconButton(
//         icon: const Icon(Icons.arrow_back_outlined, color: Color(0xFF172B4C)),
//         onPressed: _showCancelConfirmationDialog,
//       ),
//     );
//   }
//
//   Widget _buildSendButton() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.green,
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: _isSending
//           ? const Padding(
//         padding: EdgeInsets.all(8.0),
//         child: CircularProgressIndicator(color: Colors.white),
//       )
//           : IconButton(
//         icon: const Icon(Icons.send, color: Colors.white),
//         onPressed: _sendDocument,
//       ),
//     );
//   }
//
//   // =====================================================
//   // FUNGSI LOGIKA
//   // =====================================================
//
//   Future<void> _handleMainButtonAction() async {
//     if (_activeQrNotifier.value != null) {
//       final activeQr = _activeQrNotifier.value!;
//
//       setState(() {
//         qrCodes = [activeQr];
//         _activeQrNotifier.value = null;
//       });
//
//       await Future.microtask(() {});
//
//       await _saveAllQrCodesToPdf(_pdfViewerController);
//     } else {
//       _addNewQrCode();
//     }
//   }
//
//   void _addNewQrCode() async {
//     if (_activeQrNotifier.value != null) {
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         const SnackBar(content: Text('Selesaikan atau simpan tanda tangan yang ada terlebih dahulu.')),
//       );
//       return;
//     }
//
//     final result = await showInputDialog(
//       context: context,
//       formKey: _formKey,
//       nipController: nipController,
//       tujuanController: tujuanController,
//       showTujuan: true,
//       totalPages: _pdfViewerController.pageCount,
//       documentId: widget.documentId,
//     );
//
//     if (result != null && result['sign_token'] != null) {
//       final viewSize = MediaQuery.of(context).size;
//       final newQr = {
//         'sign_token': result['sign_token'],
//         'selected_page': result['selected_page'],
//         'position': Offset(
//           viewSize.width / 2 - _initialQrSize / 2,
//           viewSize.height / 2 - _initialQrSize / 2,
//         ),
//         'size': _initialQrSize,
//         'locked': false,
//       };
//       _activeQrNotifier.value = newQr;
//     }
//   }
//
//   // =====================================================
//   // Logika Kirim & Batal (Tidak berubah)
//   // =====================================================
//   Future<void> _sendDocument() async {
//     try {
//       setState(() => _isSending = true);
//       final prefs = await SharedPreferences.getInstance();
//       final authToken = prefs.getString('token');
//       if (authToken == null) throw Exception('Token tidak valid');
//
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('$baseUrl/documents/replace/${widget.documentId}'),
//       );
//       request.headers['Authorization'] = 'Bearer $authToken';
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'pdf',
//           _currentPdfPath,
//           contentType: MediaType('application', 'pdf'),
//         ),
//       );
//
//       var response = await request.send();
//       var responseBody = await response.stream.bytesToString();
//
//       if (response.statusCode == 200) {
//         scaffoldMessengerKey.currentState?.showSnackBar(
//           const SnackBar(content: Text('Dokumen berhasil dikirim!')),
//         );
//         if (mounted) {
//           Navigator.pushAndRemoveUntil(
//             context,
//             MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
//                 (route) => false,
//           );
//         }
//       } else {
//         throw Exception(
//           jsonDecode(responseBody)['message'] ?? 'Gagal mengirim dokumen',
//         );
//       }
//     } catch (e) {
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     } finally {
//       if (mounted) setState(() => _isSending = false);
//     }
//   }
//
//   Future<void> _showCancelConfirmationDialog() async {
//     await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Batalkan Dokumen'),
//         content: const Text(
//           'Apakah Anda yakin ingin membatalkan dokumen ini?',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('Tidak'),
//           ),
//           TextButton(
//             onPressed: _isProcessing
//                 ? null
//                 : () async {
//               Navigator.of(context).pop();
//               await _cancelDocumentRequest();
//             },
//             child: _isProcessing
//                 ? const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             )
//                 : const Text('Ya, Batalkan'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _cancelDocumentRequest() async {
//     try {
//       setState(() => _isProcessing = true);
//       final response = await cancelDocument(widget.documentId);
//
//       if (response['success'] == true) {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.remove('document_id');
//
//         scaffoldMessengerKey.currentState?.showSnackBar(
//           SnackBar(content: Text(response['message'] ?? 'Dokumen dibatalkan')),
//         );
//         if (mounted) {
//           Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
//             MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
//                 (route) => false,
//           );
//         }
//       } else {
//         scaffoldMessengerKey.currentState?.showSnackBar(
//           SnackBar(content: Text(response['message'] ?? 'Gagal membatalkan')),
//         );
//       }
//     } catch (e) {
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     } finally {
//       if (mounted) setState(() => _isProcessing = false);
//     }
//   }
// }

// import 'dart:io';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'dart:convert';
// import 'pdftron';
//
// import '../api/token.dart';
// import 'package:android/upload_file/generateqr.dart';
// import 'package:android/upload_file/resizeqr.dart';
// import 'package:android/bottom_navbar/bottom_navbar.dart';
//
// /// Global ScaffoldMessenger untuk notifikasi
// final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();
//
// class PdfViewerPage extends StatefulWidget {
//   final String filePath;
//   final int documentId;
//   final Map<String, dynamic>? qrData;
//
//   const PdfViewerPage({
//     Key? key,
//     required this.filePath,
//     required this.documentId,
//     this.qrData,
//   }) : super(key: key);
//
//   @override
//   State<PdfViewerPage> createState() => _PdfViewerPageState();
// }
//
// class _PdfViewerPageState extends State<PdfViewerPage> {
//   final PdfViewerController _pdfViewerController = PdfViewerController();
//   final TextEditingController nipController = TextEditingController();
//   final TextEditingController tujuanController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//
//   // Kunci untuk mendapatkan context (dan ukuran) dari SfPdfViewer secara andal
//   final GlobalKey<SfPdfViewerState> _pdfViewerStateKey = GlobalKey<
//       SfPdfViewerState>();
//
//   // State Management yang Stabil
//   final ValueNotifier<Map<String, dynamic>?> _activeQrNotifier = ValueNotifier(
//       null);
//   List<Map<String, dynamic>> qrCodes = [
//   ]; // Hanya untuk melacak QR yang SUDAH disimpan/terkunci
//   bool _isProcessing = false;
//   bool _isSending = false;
//   late String _currentPdfPath;
//
//   static const double _initialQrSize = 100.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _currentPdfPath = widget.filePath;
//
//     // ✅ FIX: Logika initState disederhanakan.
//     // Hanya aktifkan QR baru jika ada data dari widget.
//     // QR "artefak" tidak akan pernah ditambahkan ke daftar `qrCodes`.
//     if (widget.qrData != null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!mounted) return;
//         final viewSize = MediaQuery
//             .of(context)
//             .size;
//         _activeQrNotifier.value = {
//           ...widget.qrData!,
//           'position': Offset(
//             viewSize.width / 2 - _initialQrSize / 2, // Posisi awal di tengah
//             viewSize.height / 3, // Sedikit ke atas agar tidak terlalu di tengah
//           ),
//           'size': _initialQrSize,
//           'locked': false, // Selalu bisa diedit saat pertama kali muncul
//         };
//       });
//     }
//   }
//
//   // =====================================================
//   // #1. Aksi Tombol Utama (Tambah/Simpan)
//   // =====================================================
//   Future<void> _handleMainButtonAction() async {
//     final activeQr = _activeQrNotifier.value;
//     if (activeQr != null) {
//       // === Aksi: SIMPAN QR ===
//       // Panggil fungsi simpan dengan data dari notifier
//       await _saveActiveQrToPdf(activeQr);
//     } else {
//       // === Aksi: TAMBAH QR BARU ===
//       _addNewQrCode();
//     }
//   }
//
//   // =====================================================
//   // #2. Simpan QR ke PDF (Logika Paling Akurat)
//   // =====================================================
//   Future<void> _saveActiveQrToPdf(Map<String, dynamic> qrToSave) async {
//     if (_isProcessing) return;
//     setState(() => _isProcessing = true);
//     final scaffold = scaffoldMessengerKey.currentState;
//
//     try {
//       // [REVISI] Pindahkan pengambilan state ke atas untuk validasi awal
//       final pdfViewerState = _pdfViewerStateKey.currentState;
//       if (pdfViewerState == null) {
//         throw Exception('PDF Viewer state tidak ditemukan. Pastikan widget sudah ter-render.');
//       }
//
//       final Size? viewSize = _pdfViewerStateKey.currentContext?.size;
//       if (viewSize == null || viewSize.isEmpty) {
//         throw Exception('Gagal mendapatkan ukuran view PDF. Coba lagi.');
//       }
//
//       scaffold?.showSnackBar(
//           const SnackBar(content: Text('Menyimpan QR ke PDF...')));
//
//       final originalFileBytes = await File(_currentPdfPath).readAsBytes();
//       final PdfDocument document = PdfDocument(inputBytes: originalFileBytes);
//
//       final int pageIndex = (qrToSave['selected_page'] as int) - 1;
//       if (pageIndex < 0 || pageIndex >= document.pages.count) {
//         throw Exception('Halaman #$pageIndex tidak valid.');
//       }
//
//       final PdfPage pdfPage = document.pages[pageIndex];
//       final Offset position = qrToSave['position'] as Offset;
//       final double qrSize = qrToSave['size'] as double;
//       final String signToken = qrToSave['sign_token'] as String;
//
//       final imageBytes = await QrPainter(
//         data: signToken,
//         version: QrVersions.auto,
//         gapless: true,
//         eyeStyle: const QrEyeStyle(
//           eyeShape: QrEyeShape.square,
//           color: Colors.black,
//         ),
//         dataModuleStyle: const QrDataModuleStyle(
//           dataModuleShape: QrDataModuleShape.square,
//           color: Colors.black,
//         ),
//       ).toImageData(2048);
//
//       if (imageBytes == null) {
//         throw Exception('Gagal membuat gambar QR menjadi bytes.');
//       }
//
//       final PdfBitmap pdfImage = PdfBitmap(imageBytes.buffer.asUint8List());
//       final Size pageSize = pdfPage.size;
//
//       // --- KONDISI AWAL (SESUAI PERMINTAAN ANDA) ---
//       debugPrint("=== KONDISI AWAL SEBELUM KALKULASI ===");
//       debugPrint("Target Halaman ke: ${pageIndex + 1}");
//       debugPrint("Posisi QR di Layar (dx, dy): ${position.toString()}");
//       debugPrint("Ukuran QR di Layar: ${qrSize.toStringAsFixed(2)}");
//       debugPrint("Ukuran Halaman PDF (width, height): ${pageSize.toString()}");
//       debugPrint("Ukuran Widget Viewer (width, height): ${viewSize.toString()}");
//       debugPrint("========================================");
//
//       // --- START: Logika Kalkulasi yang Diperbaiki dan Lebih Akurat ---
//
//       // 1. Definisikan pojok kiri-atas dan kanan-bawah QR di layar (koordinat widget)
//       final Offset topLeftOnScreen = position;
//       final Offset bottomRightOnScreen = Offset(position.dx + qrSize, position.dy + qrSize);
//
//       // 2. [PERBAIKAN] Konversi KEDUA titik tersebut ke koordinat PDF.
//       //    Metode ini tidak 'async', jadi 'await' harus dihapus.
//       final PdfPoint topLeftPdfPoint = pdfViewerState.pointToPdfPoint(widgetPoint: topLeftOnScreen);
//       final PdfPoint bottomRightPdfPoint = pdfViewerState.pointToPdfPoint(widgetPoint: bottomRightOnScreen);
//
//       // 3. [PERBAIKAN] Buat sebuah Rect (persegi) dari dua titik PDF yang sudah dikonversi.
//       //    Ini adalah cara paling akurat untuk mendapatkan posisi (x, y) dan ukuran (width, height)
//       //    karena sudah memperhitungkan zoom, scroll, dan padding secara otomatis.
//       final Rect pdfRect = Rect.fromPoints(topLeftPdfPoint.position, bottomRightPdfPoint.position);
//
//       // --- END: Kalkulasi ---
//
//       debugPrint("=== FINAL MAPPING (SYNCFUSION METHOD) ===");
//       debugPrint("Top-Left di Layar      : $topLeftOnScreen");
//       debugPrint("Bottom-Right di Layar  : $bottomRightOnScreen");
//       debugPrint("Top-Left di PDF        : ${topLeftPdfPoint.position}");
//       debugPrint("Bottom-Right di PDF    : ${bottomRightPdfPoint.position}");
//       debugPrint("Final PDF Rect         : ${pdfRect.toString()}");
//       debugPrint("=========================================");
//
//       // Gambar QR ke halaman PDF menggunakan Rect yang sudah akurat
//       pdfPage.graphics.drawImage(pdfImage, pdfRect);
//
//       final tempPath =
//           '${Directory.systemTemp.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf';
//       await File(tempPath).writeAsBytes(await document.save());
//       document.dispose();
//
//       await File(_currentPdfPath).delete();
//       await File(tempPath).rename(_currentPdfPath);
//
//       setState(() {
//         qrCodes.add({...qrToSave, 'locked': true});
//         _activeQrNotifier.value = null;
//       });
//
//       scaffold?.showSnackBar(
//           const SnackBar(content: Text('QR berhasil disimpan!')));
//     } catch (e) {
//       scaffold?.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
//     } finally {
//       if (mounted) setState(() => _isProcessing = false);
//     }
//   }
//   // #3. UI WIDGETS
//   // =====================================================
//   @override
//   Widget build(BuildContext context) {
//     // Gunakan ValueListenableBuilder untuk FAB agar update otomatis
//     return ValueListenableBuilder<Map<String, dynamic>?>(
//       valueListenable: _activeQrNotifier,
//       builder: (context, activeQr, child) {
//         final bool hasActiveQr = activeQr != null;
//
//         return Scaffold(
//           key: scaffoldMessengerKey,
//           appBar: _buildAppBar(),
//           body: Stack(
//             children: [
//               GestureDetector(
//                 onTapDown: (details) {
//                   if (activeQr != null) {
//                     final viewSize = context.size;
//                     if (viewSize == null) return;
//                     final qrSize = activeQr['size'] as double;
//                     final newPosition = details.localPosition -
//                         Offset(qrSize / 2, qrSize / 2);
//                     _activeQrNotifier.value = {
//                       ...activeQr,
//                       'position': Offset(
//                         newPosition.dx.clamp(0, viewSize.width - qrSize),
//                         newPosition.dy.clamp(0, viewSize.height - qrSize),
//                       ),
//                       'selected_page': _pdfViewerController.pageNumber,
//                     };
//                   }
//                 },
//                 child: SfPdfViewer.file(
//                   File(_currentPdfPath),
//                   key: _pdfViewerStateKey, // Kunci dipasang di sini
//                   controller: _pdfViewerController,
//                 ),
//               ),
//
//               // ✅ FIX: Hapus loop QR terkunci dari sini.
//               // Hanya tampilkan QR yang aktif diedit.
//
//               // Render QR yang sedang aktif untuk diedit
//               if (activeQr != null)
//                 ValueListenableBuilder<Map<String, dynamic>?>(
//                   valueListenable: _activeQrNotifier,
//                   builder: (context, currentQr, _) {
//                     if (currentQr == null) return const SizedBox.shrink();
//                     return ResizableQrCode(
//                       key: ValueKey('resizable_qr_${currentQr['sign_token']}'),
//                       constraints: BoxConstraints(
//                           maxWidth: MediaQuery
//                               .of(context)
//                               .size
//                               .width,
//                           maxHeight: MediaQuery
//                               .of(context)
//                               .size
//                               .height),
//                       qrData: currentQr,
//                       onDragUpdate: (newPosition) {
//                         _activeQrNotifier.value =
//                         {...currentQr, 'position': newPosition};
//                       },
//                       onResizeUpdate: (newSize) {
//                         _activeQrNotifier.value =
//                         {...currentQr, 'size': newSize};
//                       },
//                       onDragEnd: () {
//                         final updatedQr = _activeQrNotifier.value!;
//                         _activeQrNotifier.value = {
//                           ...updatedQr,
//                           'selected_page': _pdfViewerController.pageNumber,
//                         };
//                       },
//                     );
//                   },
//                 ),
//               _buildBottomNavigation(hasActiveQr),
//               if (_isProcessing || _isSending)
//                 Container(
//                   color: Colors.black.withOpacity(0.5),
//                   child: const Center(child: CircularProgressIndicator()),
//                 ),
//             ],
//           ),
//           floatingActionButton: Visibility(
//             visible: !_isProcessing && !_isSending,
//             child: Padding(
//               padding: const EdgeInsets.only(bottom: 70.0),
//               child: FloatingActionButton.extended(
//                 backgroundColor: Colors.white,
//                 onPressed: _handleMainButtonAction,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                   side: const BorderSide(color: Colors.black, width: 2),
//                 ),
//                 label: Text(
//                   hasActiveQr ? 'Simpan Posisi QR' : '+ Tanda Tangan',
//                   style: const TextStyle(color: Colors.black),
//                 ),
//                 icon: Icon(
//                   hasActiveQr ? Icons.save : Icons.add,
//                   color: Colors.black,
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   // =====================================================
//   // Sisa Fungsi (UI dan Logika)
//   // =====================================================
//
//   AppBar _buildAppBar() {
//     return AppBar(
//       title: const Text(
//           'Edit & Tanda Tangan', style: TextStyle(color: Colors.white)),
//       backgroundColor: const Color(0xFF172B4C),
//       centerTitle: true,
//       automaticallyImplyLeading: false,
//     );
//   }
//
//   Widget _buildBottomNavigation(bool hasActiveQr) {
//     // Tampilkan tombol kirim jika tidak ada QR aktif dan sudah ada QR yang terkunci
//     final bool canSend = !hasActiveQr && qrCodes.isNotEmpty;
//
//     return Align(
//       alignment: Alignment.bottomCenter,
//       child: ClipRRect(
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(30),
//           topRight: Radius.circular(30),
//         ),
//         child: Container(
//           height: 60,
//           color: const Color(0xFF172B4C),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildBackButton(),
//               if (canSend) _buildSendButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBackButton() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: IconButton(
//         icon: const Icon(Icons.arrow_back_outlined, color: Color(0xFF172B4C)),
//         onPressed: _isProcessing || _isSending
//             ? null
//             : _showCancelConfirmationDialog,
//       ),
//     );
//   }
//
//   Widget _buildSendButton() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.green,
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: _isSending
//           ? const Padding(
//         padding: EdgeInsets.all(8.0),
//         child: CircularProgressIndicator(color: Colors.white),
//       )
//           : IconButton(
//         icon: const Icon(Icons.send, color: Colors.white),
//         onPressed: _sendDocument,
//       ),
//     );
//   }
//
//   void _addNewQrCode() async {
//     if (_activeQrNotifier.value != null) {
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         const SnackBar(content: Text(
//             'Selesaikan atau simpan tanda tangan yang ada terlebih dahulu.')),
//       );
//       return;
//     }
//
//     final result = await showInputDialog(
//       context: context,
//       formKey: _formKey,
//       nipController: nipController,
//       tujuanController: tujuanController,
//       showTujuan: true,
//       totalPages: _pdfViewerController.pageCount,
//       documentId: widget.documentId,
//     );
//
//     if (result != null && result['sign_token'] != null) {
//       final viewSize = MediaQuery
//           .of(context)
//           .size;
//       final newQr = {
//         'sign_token': result['sign_token'],
//         'selected_page': result['selected_page'],
//         'position': Offset(
//           viewSize.width / 2 - _initialQrSize / 2,
//           viewSize.height / 3,
//         ),
//         'size': _initialQrSize,
//         'locked': false,
//       };
//       _activeQrNotifier.value = newQr;
//     }
//   }
//
//   // Sisa fungsi tidak berubah
//   Future<void> _sendDocument() async {
//     // ... (Implementasi Anda sudah ada di sini)
//     try {
//       setState(() => _isSending = true);
//       final prefs = await SharedPreferences.getInstance();
//       final authToken = prefs.getString('token');
//       if (authToken == null) throw Exception('Token tidak valid');
//
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('$baseUrl/documents/replace/${widget.documentId}'),
//       );
//       request.headers['Authorization'] = 'Bearer $authToken';
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'pdf',
//           _currentPdfPath,
//           contentType: MediaType('application', 'pdf'),
//         ),
//       );
//
//       var response = await request.send();
//       var responseBody = await response.stream.bytesToString();
//
//       if (response.statusCode == 200) {
//         scaffoldMessengerKey.currentState?.showSnackBar(
//           const SnackBar(content: Text('Dokumen berhasil dikirim!')),
//         );
//         if (mounted) {
//           Navigator.pushAndRemoveUntil(
//             context,
//             MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
//                 (route) => false,
//           );
//         }
//       } else {
//         throw Exception(
//           jsonDecode(responseBody)['message'] ?? 'Gagal mengirim dokumen',
//         );
//       }
//     } catch (e) {
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     } finally {
//       if (mounted) setState(() => _isSending = false);
//     }
//   }
//
//   Future<void> _showCancelConfirmationDialog() async {
//     await showDialog(
//       context: context,
//       builder: (context) =>
//           AlertDialog(
//             title: const Text('Batalkan Dokumen'),
//             content: const Text(
//               'Apakah Anda yakin ingin membatalkan dokumen ini?',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Tidak'),
//               ),
//               TextButton(
//                 onPressed: _isProcessing
//                     ? null
//                     : () async {
//                   Navigator.of(context).pop();
//                   await _cancelDocumentRequest();
//                 },
//                 child: _isProcessing
//                     ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(strokeWidth: 2),
//                 )
//                     : const Text('Ya, Batalkan'),
//               ),
//             ],
//           ),
//     );
//   }
//
//   Future<void> _cancelDocumentRequest() async {
//     // ... (Implementasi Anda sudah ada di sini)
//     try {
//       setState(() => _isProcessing = true);
//       final response = await cancelDocument(widget.documentId);
//
//       if (response['success'] == true) {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.remove('document_id');
//
//         scaffoldMessengerKey.currentState?.showSnackBar(
//           SnackBar(content: Text(response['message'] ?? 'Dokumen dibatalkan')),
//         );
//         if (mounted) {
//           Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
//             MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
//                 (route) => false,
//           );
//         }
//       } else {
//         scaffoldMessengerKey.currentState?.showSnackBar(
//           SnackBar(content: Text(response['message'] ?? 'Gagal membatalkan')),
//         );
//       }
//     } catch (e) {
//       scaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(content: Text('Error: ${e.toString()}')),
//       );
//     } finally {
//       if (mounted) setState(() => _isProcessing = false);
//     }
//   }
// }
//
