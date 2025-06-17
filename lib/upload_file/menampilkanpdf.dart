import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:android/api/token.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:android/upload_file/generateqr.dart';

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final int documentId;
  final Map<String, dynamic>? qrData; // Tambahkan parameter untuk data QR

  const PdfViewerPage({
    Key? key,
    required this.filePath,
    required this.documentId,
    this.qrData, // Parameter opsional untuk QR data
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
  bool qrLocked = false;
  static const double qrDisplaySize = 100.0;
  static const double qrPdfSize = 100.0;

  @override
  void initState() {
    super.initState();
    // Inisialisasi QR data jika ada dari parameter
    if (widget.qrData != null) {
      _initializeQrFromData(widget.qrData!);
    }
  }

  void _initializeQrFromData(Map<String, dynamic> qrData) {
    setState(() {
      currentQrData = qrData['sign_token'];
      qrPageNumber = qrData['selected_page'] ?? 1;
      // Set posisi default di tengah layar
      qrPosition = Offset(
        MediaQuery.of(context).size.width / 2 - qrDisplaySize / 2,
        MediaQuery.of(context).size.height / 2 - qrDisplaySize / 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.filePath);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF172B4C),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Container(),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: (details) {
              // Jika QR belum dikunci, update posisi saat tap
              if (currentQrData != null && !qrLocked) {
                setState(() {
                  qrPosition = details.localPosition;
                  qrPageNumber = pdfViewerController.pageNumber;
                });
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
              left: qrPosition!.dx.clamp(
                0.0,
                MediaQuery.of(context).size.width - qrDisplaySize,
              ),
              top: qrPosition!.dy.clamp(
                0.0,
                MediaQuery.of(context).size.height - qrDisplaySize,
              ),
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
                    Container(
                      width: qrDisplaySize,
                      height: qrDisplaySize,
                      color: Colors.white,
                      child: QrImageView(
                        data: "$baseUrl/$currentQrData",
                        version: QrVersions.auto,
                        size: qrDisplaySize,
                        padding: const EdgeInsets.all(5.0),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.lock,
                        color: Colors.black,
                        size: 24,
                      ),
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
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

                        setState(() {
                          qrLocked = true;
                          currentQrData = null;
                          qrPosition = null;
                          qrPageNumber = null;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('QR berhasil disimpan ke PDF!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: Container(
                height: 60,
                color: const Color(0xFF172B4C),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_outlined,
                            color: Color(0xFF172B4C),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      FloatingActionButton.extended(
                        backgroundColor: Colors.white,
                        onPressed: () async {
                          if (currentQrData != null && !qrLocked) {
                            ScaffoldMessenger.of(context).showSnackBar(
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
                            ScaffoldMessenger.of(context).showSnackBar(
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
        data: "$baseUrl/$data",
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      ).qrCode!,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );

    final ui.Image qrImage = await qrPainter.toImage(qrPdfSize.toInt() * 3);

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
    final Size pdfViewerScreenSize = pdfViewerRenderBox.size;

    final double currentZoom = pdfViewerController.zoomLevel;
    final Offset currentScrollOffset = pdfViewerController.scrollOffset;

    final double currentViewerWidth = pdfViewerScreenSize.width;
    final double currentViewerHeight = pdfViewerScreenSize.height;

    final double actualPdfWidthPerViewerPixel =
        pdfPage.size.width / (currentViewerWidth * currentZoom);
    final double actualPdfHeightPerViewerPixel =
        pdfPage.size.height / (currentViewerHeight * currentZoom);

    final double pdfX =
        (offset.dx + currentScrollOffset.dx) * actualPdfWidthPerViewerPixel;
    final double pdfY =
        (offset.dy + currentScrollOffset.dy) * actualPdfHeightPerViewerPixel;

    pdfPage.graphics.drawImage(
      pdfImage,
      Rect.fromLTWH(pdfX, pdfY, qrPdfSize, qrPdfSize),
    );

    final String outputPath =
        '${widget.filePath.substring(0, widget.filePath.lastIndexOf('.'))}_signed.pdf';
    final File newFile = File(outputPath);
    await newFile.writeAsBytes(await document.save());
    document.dispose();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PdfViewerPage(filePath: outputPath, documentId: widget.documentId),
      ),
    );
  }
}
