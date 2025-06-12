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
  State<PdfViewerPage> createState() => _PdfViewerPageState();
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
        title: const Text('Edit PDF', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF172B4C),
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
                  final newPos = await convertToPdfCoordinates(offset);
                  setState(() {
                    qrPositions[i] = newPos;
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
              onPressed: insertQrToPdf,
              label: const Text('Simpan ke PDF'),
              icon: const Icon(Icons.save),
              backgroundColor: Colors.green,
            ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            backgroundColor: Colors.white,
            onPressed: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Data Tanda Tangan'),
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
                            labelText: 'Tujuan',
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

              if (result != null) {
                setState(() {
                  qrDataList.add(result['encrypted_link']);
                  qrPositions.add(const Offset(100, 100));
                  qrPages.add(result['selected_page']);
                });
              }
            },
            label: const Text(
              '+ Tanda Tangan',
              style: TextStyle(color: Colors.black),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.black),
            ),
          ),
          const SizedBox(height: 70),
        ],
      ),
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
    final originalBytes = await File(widget.filePath).readAsBytes();
    final document = PdfDocument(inputBytes: originalBytes);

    for (int i = 0; i < qrDataList.length; i++) {
      final qrImage = await QrPainter.withQr(
        qr: QrValidator.validate(
          data:
              'http://fakerryugan.my.id/api/signature/view-from-payload?payload=${qrDataList[i]}',
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
        ).qrCode!,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      ).toImage(200);

      final byteData = await qrImage.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final pdfImage = PdfBitmap(bytes);

      final pageIndex = qrPages[i];
      final page = document.pages[pageIndex];

      final Offset position = qrPositions[i];

      // Tempel QR di koordinat PDF
      page.graphics.drawImage(
        pdfImage,
        Rect.fromLTWH(position.dx, position.dy, 100, 100),
      );
    }

    final newPath = widget.filePath.replaceAll('.pdf', '_signed.pdf');
    final outputFile = File(newPath);
    await outputFile.writeAsBytes(await document.save());
    document.dispose();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PdfViewerPage(filePath: newPath)),
    );
  }

  Future<Offset> convertToPdfCoordinates(Offset screenOffset) async {
    final renderBox = context.findRenderObject() as RenderBox;
    final localOffset = renderBox.globalToLocal(screenOffset);

    final zoom = _pdfViewerController.zoomLevel;

    // Asumsi ukuran standar A4
    const pageWidth = 595.0;
    const pageHeight = 842.0;

    final relativeX = localOffset.dx / renderBox.size.width;
    final relativeY = localOffset.dy / renderBox.size.height;

    final pdfX = relativeX * pageWidth / zoom;
    final pdfY = relativeY * pageHeight / zoom;

    return Offset(pdfX, pdfY);
  }
}
