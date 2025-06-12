import 'dart:io';
import 'package:android/upload_file/generateqr.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
          SfPdfViewer.file(file),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.white,
          onPressed: () {
            showInputDialog(
              context: context,
              formKey: _formKey,
              nipController: nipController,
              tujuanController: tujuanController,
              showTujuan: true,
            );
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
