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
  List<Offset> qrPositions = []; // stored as ratio (0.0 - 1.0)
  List<int> qrPages = [];
  List<bool> isLockedList = [];
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pdfController = pdfx.PdfControllerPinch(
      document: pdfx.PdfDocument.openFile(widget.filePath),
    );

    _pdfController.pageListenable.addListener(() {
      setState(() {
        currentPage = _pdfController.pageListenable.value;
      });
    });
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

  Widget qrDraggable(int index) {
    return isLockedList[index]
        ? qrWidget(qrDataList[index])
        : Stack(
            alignment: Alignment.topRight,
            children: [
              qrWidget(qrDataList[index]),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isLockedList[index] = true;
                  });
                },
                child: const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
            ],
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              pdfx.PdfViewPinch(controller: _pdfController),
              for (int i = 0; i < qrDataList.length; i++)
                if (qrPages[i] + 1 == currentPage)
                  Positioned(
                    left: qrPositions[i].dx * constraints.maxWidth,
                    top: qrPositions[i].dy * constraints.maxHeight,
                    child: isLockedList[i]
                        ? qrWidget(qrDataList[i])
                        : Draggable(
                            feedback: qrWidget(qrDataList[i]),
                            childWhenDragging: const SizedBox(),
                            onDraggableCanceled: (_, offset) {
                              setState(() {
                                qrPositions[i] = Offset(
                                  offset.dx / constraints.maxWidth,
                                  offset.dy / constraints.maxHeight,
                                );
                                qrPages[i] = currentPage - 1;
                              });
                            },
                            child: qrDraggable(i),
                          ),
                  ),
            ],
          );
        },
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
                setState(() {
                  qrDataList.add(result['encrypted_link']);
                  qrPositions.add(
                    const Offset(0.2, 0.2),
                  ); // posisi awal relatif
                  qrPages.add(currentPage - 1);
                  isLockedList.add(false);
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

      final page = document.pages[qrPages[i]];
      final pageSize = page.getClientSize();

      final pdfX = qrPositions[i].dx * pageSize.width;
      final pdfY =
          pageSize.height - (qrPositions[i].dy * pageSize.height) - 100;

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
