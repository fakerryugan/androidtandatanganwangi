import 'dart:io';
import 'package:android/system/inserQRkePDF.dart';
import 'package:android/system/systemupload.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:android/api/token.dart';
import 'package:android/upload_file/generateqr.dart';

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final int documentId;
  final String accessToken;

  const PdfViewerPage({
    super.key,
    required this.filePath,
    required this.accessToken,
    required this.documentId,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'QR Code ditempatkan. Geser/kunci untuk simpan.',
                        ),
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
                      icon: const Icon(Icons.lock, color: Colors.black),
                      onPressed: () async {
                        if (qrPageNumber == null ||
                            qrPageNumber! <= 0 ||
                            qrPageNumber! > pdfViewerController.pageCount) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Halaman QR tidak valid'),
                            ),
                          );
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Menyimpan QR ke PDF...'),
                          ),
                        );

                        await QrPdfHelper.insertQrToPdfDirectly(
                          context: context,
                          filePath: widget.filePath,
                          fullUrl: "$baseUrl/$currentQrData",
                          page: qrPageNumber!,
                          offset: qrPosition!,
                          pdfViewerKey: _pdfViewerKey,
                          pdfViewerController: pdfViewerController,
                          documentId: widget.documentId,
                        );

                        setState(() {
                          qrLocked = true;
                          waitingForTap = false;
                          currentQrData = null;
                          qrPosition = null;
                          qrPageNumber = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.white,
        onPressed: () async {
          if (waitingForTap || qrLocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Selesaikan QR sebelumnya.')),
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
              const SnackBar(content: Text('Tap PDF untuk tempatkan QR.')),
            );
          }
        },
        label: const Text(
          '+ Tanda tangan',
          style: TextStyle(color: Colors.black),
        ),
      ),
      bottomNavigationBar: Align(
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
                  if (qrLocked && currentQrData == null) ...[
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
                        icon: const Icon(Icons.send, color: Color(0xFF172B4C)),
                        onPressed: () {
                          PdfPickerHelper.uploadSignedPdf(
                            context: context,
                            filePath: widget.filePath,
                            documentId: widget.documentId,
                            documentAccessToken: widget.accessToken,
                          );
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
    );
  }
}
