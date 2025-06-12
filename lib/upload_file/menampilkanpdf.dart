import 'dart:io';
import 'package:android/system/posisiqr.dart';
import 'package:android/system/uploadpdf.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:android/api/dokumen.dart';
import 'package:android/api/token.dart';
import 'package:android/upload_file/generateqr.dart';

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
  List<bool> isLockedList = [];
  List<double> qrSizes = [];
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pdfController = pdfx.PdfControllerPinch(
      document: pdfx.PdfDocument.openFile(widget.filePath),
    );
    _pdfController.pageListenable.addListener(() {
      final newPage = _pdfController.pageListenable.value;
      if (newPage != currentPage) {
        setState(() {
          currentPage = newPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _pdfController.dispose();
    nipController.dispose();
    tujuanController.dispose();
    super.dispose();
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
              GestureDetector(
                onTapDown: (details) {
                  if (qrDataList.length > qrPositions.length) {
                    final renderBox = context.findRenderObject() as RenderBox;
                    final localPosition = renderBox.globalToLocal(
                      details.globalPosition,
                    );
                    final normalizedOffset = Offset(
                      localPosition.dx / constraints.maxWidth,
                      localPosition.dy / constraints.maxHeight,
                    );
                    setState(() {
                      qrPositions.add(normalizedOffset);
                      qrPages.add(currentPage - 1);
                      isLockedList.add(true);
                      qrSizes.add(100);
                    });
                  }
                },
                child: pdfx.PdfViewPinch(controller: _pdfController),
              ),
              for (int i = 0; i < qrPositions.length; i++)
                if (qrPages[i] + 1 == currentPage)
                  Positioned(
                    left: qrPositions[i].dx * constraints.maxWidth,
                    top: qrPositions[i].dy * constraints.maxHeight,
                    child: QrOverlay(
                      data: qrDataList[i],
                      locked: isLockedList[i],
                      initialSize: qrSizes[i],
                      onResize: (newSize) =>
                          setState(() => qrSizes[i] = newSize),
                      onLock: () => setState(() => isLockedList[i] = true),
                      onDragEnd: (offset) {
                        setState(() {
                          qrPositions[i] = Offset(
                            offset.dx / constraints.maxWidth,
                            offset.dy / constraints.maxHeight,
                          );
                          qrPages[i] = currentPage - 1;
                        });
                      },
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
                  label: const Text('Kirim'),
                  onPressed: () async {
                    final documentId = await DocumentInfo.getDocumentId();
                    final accessToken = await getToken();
                    final signedFilePath = await insertQrToPdf(
                      filePath: widget.filePath,
                      qrDataList: qrDataList,
                      qrPositions: qrPositions,
                      qrPages: qrPages,
                    );
                    await uploadReplacedPdf(
                      documentId.toString(),
                      accessToken ?? '',
                      signedFilePath,
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
