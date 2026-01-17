import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/token.dart';
import '../features/upload/menampilkanpdf.dart';

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
      // 1. Upload Document
      final data = await uploadDocument(file);

      // Ambil Access Token DOKUMEN (UUID) & Security Code
      final String docToken = data['access_token'];
      final String? securityCode = data['security_code'];
      
      // NOTE: QR Footer & Tanda Tangan akan ditempel oleh BACKEND setelah selesai.
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(
            filePath: file.path, 
            accessToken: docToken, 
            securityCode: securityCode,
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
