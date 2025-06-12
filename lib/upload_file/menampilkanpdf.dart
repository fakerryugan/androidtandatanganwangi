import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:android/api/dokumen.dart';
import 'package:android/api/token.dart';
import 'package:android/system/uploadpdf.dart';

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  const PdfViewerPage({Key? key, required this.filePath}) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late pdfx.PdfControllerPinch _pdfController;
  int currentPage = 0;

  List<Offset> qrPositions = [];
  List<int> qrPages = [];

  @override
  void initState() {
    super.initState();
    _pdfController = pdfx.PdfControllerPinch(
      document: pdfx.PdfDocument.openFile(widget.filePath),
    );

    _pdfController.pageListenable.addListener(() {
      final newPage = _pdfController.pageListenable.value;
      if (newPage != currentPage) {
        setState(() => currentPage = newPage);
      }
    });
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tandai Lokasi TTD',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF172B4C),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              GestureDetector(
                onTapDown: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final localOffset = box.globalToLocal(details.globalPosition);

                  final normalized = Offset(
                    localOffset.dx / constraints.maxWidth,
                    localOffset.dy / constraints.maxHeight,
                  );

                  setState(() {
                    qrPositions.add(normalized);
                    qrPages.add(currentPage - 1);
                  });
                },
                child: pdfx.PdfViewPinch(controller: _pdfController),
              ),

              // Tampilkan penanda posisi QR (tanda kecil)
              for (int i = 0; i < qrPositions.length; i++)
                if (qrPages[i] + 1 == currentPage)
                  Positioned(
                    left: qrPositions[i].dx * constraints.maxWidth,
                    top: qrPositions[i].dy * constraints.maxHeight,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.edit_location,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
      bottomNavigationBar: qrPositions.isNotEmpty
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
                  label: const Text('Kirim dan Tambah QR'),
                  onPressed: () async {
                    final documentId = await DocumentInfo.getDocumentId();
                    final token = await getToken();

                    // QR code isi bisa dibuat per dokumen atau statis sesuai kebutuhan
                    final List<String> qrDataList = List.generate(
                      qrPositions.length,
                      (_) =>
                          'EncryptedPayloadHere', // ganti sesuai hasil generate
                    );

                    final signedPath = await insertQrToPdf(
                      filePath: widget.filePath,
                      qrDataList: qrDataList,
                      qrPositions: qrPositions,
                      qrPages: qrPages,
                    );

                    await uploadReplacedPdf(
                      documentId.toString(),
                      token ?? '',
                      signedPath,
                      context,
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }
}
