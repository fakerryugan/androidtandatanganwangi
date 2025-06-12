import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr/qr.dart';

class PdfViewerPage extends StatefulWidget {
  final String filePath;

  const PdfViewerPage({Key? key, required this.filePath}) : super(key: key);

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  final TextEditingController nipController = TextEditingController();
  final TextEditingController tujuanController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<String> qrDataList = [];
  List<Offset> qrPositions = [];
  List<int> qrPages = [];

  int totalPages = 1;

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
        title: const Text('Edit', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF172B4C),
        automaticallyImplyLeading: false,
        leading: const SizedBox(),
      ),
      body: Stack(
        children: [
          SfPdfViewer.file(
            file,
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            onDocumentLoaded: (details) {
              setState(() {
                totalPages = details.document.pages.count;
              });
            },
          ),
          for (int i = 0; i < qrDataList.length; i++)
            Positioned(
              left: qrPositions[i].dx,
              top: qrPositions[i].dy,
              child: Draggable(
                feedback: qrWidget(qrDataList[i]),
                childWhenDragging: const SizedBox(),
                onDraggableCanceled: (_, offset) async {
                  final converted = await convertToPdfCoordinates(
                    offset,
                    qrPages[i],
                  );
                  setState(() {
                    qrPositions[i] = converted;
                  });
                },
                child: qrWidget(qrDataList[i]),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (qrDataList.isNotEmpty)
            FloatingActionButton.extended(
              backgroundColor: Colors.green,
              onPressed: () async {
                await insertQrToPdf();
              },
              label: const Text('Simpan ke PDF'),
              icon: const Icon(Icons.save),
            ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            backgroundColor: Colors.white,
            onPressed: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Masukkan Data QR'),
                  content: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nipController,
                          decoration: const InputDecoration(
                            labelText: 'NIP/NIM',
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Wajib diisi' : null,
                        ),
                        TextFormField(
                          controller: tujuanController,
                          decoration: const InputDecoration(
                            labelText: 'Alasan / Tujuan',
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Wajib diisi' : null,
                        ),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Halaman',
                          ),
                          items: List.generate(totalPages, (index) {
                            return DropdownMenuItem(
                              value: index,
                              child: Text('Halaman ${index + 1}'),
                            );
                          }),
                          onChanged: (value) {
                            Navigator.pop(context, {
                              'encrypted_link': Uri.encodeComponent(
                                '${nipController.text}_${tujuanController.text}_${DateTime.now().millisecondsSinceEpoch}',
                              ),
                              'selected_page': value,
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (result != null && result['encrypted_link'] != null) {
                setState(() {
                  qrDataList.add(result['encrypted_link']);
                  qrPositions.add(
                    const Offset(100, 100),
                  ); // sementara, akan dikonversi saat drag
                  qrPages.add(result['selected_page']);
                });
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
          const SizedBox(height: 70),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget qrWidget(String data) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: Colors.white,
      ),
      child: QrImageView(
        data:
            'http://fakerryugan.my.id/api/signature/view-from-payload?payload=$data',
        version: QrVersions.auto,
      ),
    );
  }

  Future<void> insertQrToPdf() async {
    final fileBytes = await File(widget.filePath).readAsBytes();
    final document = PdfDocument(inputBytes: fileBytes);

    for (int i = 0; i < qrDataList.length; i++) {
      final qrImage = await QrPainter.withQr(
        qr: QrValidator.validate(
          data:
              'http://fakerryugan.my.id/api/signature/view-from-payload?payload=${qrDataList[i]}',
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
        ).qrCode!,
        gapless: true,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      ).toImage(200);

      final byteData = await qrImage.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final pdfImage = PdfBitmap(bytes);

      final pageIndex = qrPages[i];
      final pdfOffset = qrPositions[i];

      document.pages[pageIndex].graphics.drawImage(
        pdfImage,
        Rect.fromLTWH(pdfOffset.dx, pdfOffset.dy, 100, 100),
      );
    }

    final outputPath = '${widget.filePath}_signed.pdf';
    final file = File(outputPath);
    await file.writeAsBytes(await document.save());
    document.dispose();

    // Ganti tampilan ke PDF baru
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(filePath: outputPath),
      ),
    );
  }

  Future<Offset> convertToPdfCoordinates(
    Offset screenOffset,
    int pageIndex,
  ) async {
    final renderBox = context.findRenderObject() as RenderBox;
    final localOffset = renderBox.globalToLocal(screenOffset);

    final zoom = _pdfViewerController.zoomLevel;

    // Asumsikan ukuran halaman standar A4 595 x 842 points
    const pageWidth = 595.0;
    const pageHeight = 842.0;

    final pdfX = localOffset.dx / zoom;
    final pdfY = localOffset.dy / zoom;

    return Offset(pdfX, pdfY);
  }
}
