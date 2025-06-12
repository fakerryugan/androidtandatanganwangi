import 'dart:io';
import 'dart:ui' as ui;
import 'package:android/upload_file/generateqr.dart';
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
  final TextEditingController nipController = TextEditingController();
  final TextEditingController tujuanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final PdfViewerController _pdfViewerController = PdfViewerController();

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
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Container(),
      ),
      body: Stack(
        children: [
          SfPdfViewer.file(
            file,
            controller: _pdfViewerController,
            onDocumentLoaded: (details) {
              setState(() {
                totalPages = details.document.pages.count;
              });
            },
          ),
          for (int i = 0; i < qrDataList.length; i++)
            Positioned(
              left: qrPositions[i].dx * _pdfViewerController.zoomLevel,
              top:
                  (getPageOffset(i) -
                  (qrPositions[i].dy * _pdfViewerController.zoomLevel)),
              child: Draggable(
                feedback: qrWidget(qrDataList[i]),
                childWhenDragging: const SizedBox(),
                onDraggableCanceled: (_, offset) {
                  // Konversi posisi layar ke posisi relatif halaman PDF
                  RenderBox renderBox = context.findRenderObject() as RenderBox;
                  Offset localOffset = renderBox.globalToLocal(offset);

                  double zoom = _pdfViewerController.zoomLevel;
                  double scrollY = _pdfViewerController.scrollOffset.dy;

                  final pageHeightPdf = 842.0; // default A4 height
                  final pageHeightScreen = pageHeightPdf * zoom;
                  int pageIndex = (scrollY / pageHeightScreen).floor();

                  double positionInPageY =
                      (localOffset.dy + scrollY) -
                      (pageHeightScreen * pageIndex);
                  double convertedY = pageHeightPdf - (positionInPageY / zoom);
                  double convertedX = localOffset.dx / zoom;

                  setState(() {
                    qrPositions[i] = Offset(convertedX, convertedY);
                    qrPages[i] = pageIndex;
                  });
                },
                child: qrWidget(qrDataList[i]),
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
                    ],
                  ),
                ),
              ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR berhasil disimpan ke PDF')),
                );
              },
              label: const Text('Simpan ke PDF'),
              icon: const Icon(Icons.save),
            ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            backgroundColor: Colors.white,
            onPressed: () async {
              final result = await showInputDialog(
                context: context,
                formKey: _formKey,
                nipController: nipController,
                tujuanController: tujuanController,
                showTujuan: true,
                totalPages: totalPages,
              );

              if (result != null && result['encrypted_link'] != null) {
                setState(() {
                  qrDataList.add(result['encrypted_link']);
                  qrPositions.add(const Offset(100, 100));
                  qrPages.add(result['selected_page'] ?? 0);
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

  double getPageOffset(int index) {
    double zoom = _pdfViewerController.zoomLevel;
    double pageHeight = 842 * zoom; // asumsi ukuran A4
    return (qrPages[index]) * pageHeight;
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

      final offset = qrPositions[i];
      final pageIndex = qrPages[i];
      document.pages[pageIndex].graphics.drawImage(
        pdfImage,
        Rect.fromLTWH(offset.dx, offset.dy, 100, 100),
      );
    }

    final outputPath = '${widget.filePath}_signed.pdf';
    final file = File(outputPath);
    await file.writeAsBytes(await document.save());
    document.dispose();

    setState(() {
      qrDataList.clear();
      qrPositions.clear();
      qrPages.clear();
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(filePath: outputPath),
      ),
    );
  }
}
