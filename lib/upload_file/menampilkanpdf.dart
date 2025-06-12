import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:android/api/dokumen.dart';
import 'package:android/api/token.dart';
import 'package:http/http.dart' as http;
import 'package:android/upload_file/generateqr.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  const PdfViewerPage({Key? key, required this.filePath}) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late pdfx.PdfControllerPinch _pdfController;

  final TextEditingController nipController = TextEditingController();
  final TextEditingController tujuanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<String> qrDataList = [];
  List<Offset> qrPositions = [];
  List<int> qrPages = [];

  @override
  void initState() {
    super.initState();
    _pdfController = pdfx.PdfControllerPinch(
      document: pdfx.PdfDocument.openFile(widget.filePath),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    nipController.dispose();
    tujuanController.dispose();
    super.dispose();
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
        data: '$baseUrl/signature/view-from-payload?payload=$data',
        version: QrVersions.auto,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          pdfx.PdfViewPinch(
            controller: _pdfController,
            builders: pdfx.PdfViewPinchBuilders<pdfx.DefaultBuilderOptions>(
              options: const pdfx.DefaultBuilderOptions(),
              documentLoaderBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
              pageLoaderBuilder: (_) =>
                  const Center(child: CircularProgressIndicator()),
            ),
          ),
          // Overlay QR code sesuai halaman aktif
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final currentPage = _pdfController.page;
                return Stack(
                  children: [
                    for (int i = 0; i < qrPages.length; i++)
                      if (qrPages[i] == currentPage - 1)
                        Positioned(
                          left: qrPositions[i].dx,
                          top: qrPositions[i].dy,
                          child: Draggable(
                            feedback: qrWidget(qrDataList[i]),
                            childWhenDragging: const SizedBox(),
                            onDraggableCanceled: (_, offset) {
                              setState(() {
                                qrPositions[i] = offset;
                              });
                            },
                            child: qrWidget(qrDataList[i]),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              );

              if (result != null && result['encrypted_link'] != null) {
                final currentPage = _pdfController.page;
                setState(() {
                  qrDataList.add(result['encrypted_link']);
                  qrPositions.add(const Offset(100, 100));
                  qrPages.add(currentPage - 1);
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
      bottomNavigationBar: qrDataList.isNotEmpty
          ? BottomAppBar(
              height: 60,
              color: const Color(0xFF172B4C),
              child: Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF172B4C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text('Kirim'),
                  onPressed: () async {
                    final documentId = await DocumentInfo.getDocumentId();
                    final accessToken = await getToken();
                    final signedFilePath = await insertQrToPdf();

                    await uploadReplacedPdf(
                      documentId.toString(),
                      accessToken ?? '',
                      signedFilePath,
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }

  Future<String> insertQrToPdf() async {
    final fileBytes = await File(widget.filePath).readAsBytes();
    final document = syncfusion.PdfDocument(inputBytes: fileBytes);

    for (int i = 0; i < qrDataList.length; i++) {
      final qrImage = await QrPainter.withQr(
        qr: QrValidator.validate(
          data: '$baseUrl/signature/view-from-payload?payload=${qrDataList[i]}',
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
        ).qrCode!,
        gapless: true,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      ).toImage(200);

      final byteData = await qrImage.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final pdfImage = syncfusion.PdfBitmap(bytes);

      final offset = qrPositions[i];
      final page = document.pages[qrPages[i]];
      final pageSize = page.getClientSize();

      final pdfX = offset.dx;
      final pdfY = pageSize.height - offset.dy - 100;

      page.graphics.drawImage(pdfImage, Rect.fromLTWH(pdfX, pdfY, 100, 100));
    }

    final tempPath = '${widget.filePath}_signed_temp.pdf';
    final file = File(tempPath);
    await file.writeAsBytes(await document.save());
    document.dispose();
    return tempPath;
  }

  Future<void> uploadReplacedPdf(
    String documentId,
    String accessToken,
    String filePath,
  ) async {
    final uri = Uri.parse('$baseUrl/documents/replace/$documentId');

    final request = http.MultipartRequest('POST', uri)
      ..fields['access_token'] = accessToken
      ..files.add(await http.MultipartFile.fromPath('new_file', filePath));

    final response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil mengganti PDF di server')),
      );
    } else {
      final respStr = await response.stream.bytesToString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal upload: $respStr')));
    }
  }
}
