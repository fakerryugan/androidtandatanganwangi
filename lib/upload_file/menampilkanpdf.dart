import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:android/api/token.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:android/system/systemupload.dart';
import 'package:android/upload_file/generateqr.dart';

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final int documentId;
  final String accessToken;

  const PdfViewerPage({
    Key? key,
    required this.filePath,
    required this.accessToken,
    required this.documentId,
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
  bool waitingForTap = false;
  bool qrLocked = false;
  static const double qrDisplaySize = 100.0;
  static const double qrPdfSize = 100.0;

  @override
  void dispose() {
    nipController.dispose();
    tujuanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.filePath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit PDF', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF172B4C),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: waitingForTap && !qrLocked
                ? (details) {
                    setState(() {
                      qrPosition = details.localPosition;
                      qrPageNumber = pdfViewerController.pageNumber;
                      waitingForTap = false;
                    });
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'QR Code ditempatkan. Anda bisa menggesernya atau tekan kunci.',
                        ),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                : null,
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
                          waitingForTap = false;
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (currentQrData != null) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_outlined,
                              color: Color(0xFF172B4C),
                            ),

                            onPressed: () async {
                              await PdfPickerHelper.cancelRequest(
                                context: context,
                                documentId: widget.documentId,
                              );
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Color(0xFF172B4C),
                            ),
                            onPressed: () {
                              PdfPickerHelper.uploadSignedPdf(
                                context: context,
                                filePath: widget.filePath,
                                documentId: widget.documentId,
                                documentAccessToken: widget.accessToken,
                              );
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ] else ...[
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
                            onPressed: () async {
                              await PdfPickerHelper.cancelRequest(
                                context: context,
                                documentId: widget.documentId,
                              );
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.white,
          onPressed: () async {
            if (waitingForTap || qrLocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Selesaikan penempatan QR sebelumnya atau tunggu.',
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
              setState(() {
                currentQrData = result['sign_token'];
                waitingForTap = true;
                qrLocked = false;
                qrPosition = null;
                qrPageNumber = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Silakan tap di PDF untuk menempatkan QR Code. Anda bisa menggesernya.',
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
        builder: (_) => PdfViewerPage(
          filePath: outputPath,
          documentId: widget.documentId,
          accessToken: '',
        ),
      ),
    );
  }
}
