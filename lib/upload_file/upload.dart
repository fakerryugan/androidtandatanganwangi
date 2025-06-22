import 'dart:io';
import 'package:android/api/token.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../upload_file/menampilkanpdf.dart';

class PdfPickerHelper {
  static Future<void> pickAndOpenPdf(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.single.path == null) {
      _showMessage(context, 'File tidak dipilih.');
      return;
    }

    final file = File(result.files.single.path!);

    try {
      final data = await uploadDocument(file);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('document_id', data['document_id']);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
            filePath: file.path,
            documentId: data['document_id'],
          ),
        ),
      );
    } catch (e) {
      _showMessage(context, 'Upload gagal: $e');
    }
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
