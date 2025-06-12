import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/rendering.dart';

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final String encryptedLink;

  const PdfViewerPage({
    Key? key,
    required this.filePath,
    required this.encryptedLink,
  }) : super(key: key);

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late File file;
  final GlobalKey repaintBoundaryKey = GlobalKey();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  PdfViewerController pdfViewerController = PdfViewerController();
  Offset? qrPosition;
  int? qrPageNumber;
  bool qrLocked = false;

  @override
  void initState() {
    super.initState();
    file = File(widget.filePath);
  }

  Future<void> insertQrAsScreenshotToPdf({required int page}) async {
    try {
      RenderRepaintBoundary boundary =
          repaintBoundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) throw Exception("Failed to convert image.");
      Uint8List pngBytes = byteData.buffer.asUint8List();

      final fileBytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: fileBytes);

      final PdfBitmap pdfImage = PdfBitmap(pngBytes);
      final int pageIndex = page - 1;
      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        throw Exception('Halaman tidak valid.');
      }

      final PdfPage pdfPage = document.pages[pageIndex];
      final Size pageSize = pdfPage.size;

      pdfPage.graphics.drawImage(
        pdfImage,
        Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
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
            encryptedLink: widget.encryptedLink,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menyimpan QR: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Viewer"),
        actions: [
          if (!qrLocked && qrPosition != null)
            IconButton(
              icon: Icon(Icons.lock),
              onPressed: () async {
                setState(() => qrLocked = true);
                await insertQrAsScreenshotToPdf(page: qrPageNumber!);
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          RepaintBoundary(
            key: repaintBoundaryKey,
            child: GestureDetector(
              onTapDown: (details) async {
                if (!qrLocked) {
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
          ),
          if (qrPosition != null &&
              qrPageNumber == pdfViewerController.pageNumber)
            Positioned(
              left: qrPosition!.dx - 50,
              top: qrPosition!.dy - 50,
              child: IgnorePointer(
                ignoring: qrLocked,
                child: Draggable(
                  feedback: _buildQrWidget(),
                  childWhenDragging: Container(),
                  onDraggableCanceled: (velocity, offset) {
                    RenderBox box = context.findRenderObject() as RenderBox;
                    final local = box.globalToLocal(offset);
                    setState(() => qrPosition = local);
                  },
                  child: _buildQrWidget(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQrWidget() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        color: Colors.white,
      ),
      child: Center(
        child: QrImageView(
          data: widget.encryptedLink,
          version: QrVersions.auto,
          size: 80,
        ),
      ),
    );
  }
}
