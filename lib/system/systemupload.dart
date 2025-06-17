import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:android/api/token.dart';
import '../upload_file/menampilkanpdf.dart';

class PdfPickerHelper {
  /// Pick PDF file, upload, and open in viewer
  static Future<void> pickAndOpenPdf(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) {
      _showMessage(context, 'File tidak dipilih.');
      return;
    }

    final file = File(result.files.single.path!);

    try {
      final data = await uploadDocument(file);

      if (data == null) throw Exception('Server tidak mengembalikan data');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('document_id', data['document_id']);
      await prefs.setString('document_access_token', data['access_token']);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
            filePath: file.path,
            documentId: data['document_id'],
            accessToken: data['access_token'],
          ),
        ),
      );
    } catch (e) {
      _showMessage(context, 'Upload gagal: $e');
    }
  }

  /// Upload PDF document
  static Future<Map<String, dynamic>?> uploadDocument(File file) async {
    final token = await getToken();
    if (token == null) throw Exception('Token login tidak ditemukan');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/documents/upload'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('application', 'pdf'),
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      final body = jsonDecode(responseBody);
      throw Exception(body?['message'] ?? 'Upload gagal');
    }
  }

  static Future<void> uploadSignedPdf({
    required BuildContext context,
    required String filePath,
    required int documentId,
    required String documentAccessToken,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token login tidak ditemukan');

      final fileToSend = File(filePath);

      if (!await fileToSend.exists()) {
        _showMessage(context, 'File PDF baru tidak ditemukan');
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/documents/replace/$documentId'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['access_token'] = documentAccessToken;

      request.files.add(
        await http.MultipartFile.fromPath(
          'new_file',
          fileToSend.path,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        debugPrint('Upload berhasil: $responseBody');
        _showMessage(context, 'PDF berhasil dikirim ke server!');
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        final body = jsonDecode(responseBody);
        final message = body?['message'] ?? responseBody;
        _showMessage(context, 'Upload gagal: $message');
      }
    } catch (e) {
      _showMessage(context, 'Error: $e');
    }
  }

  /// Cancel request (batalkan tanda tangan)
  static Future<void> cancelRequest({
    required BuildContext context,
    required int documentId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Token login tidak ditemukan');

      final prefs = await SharedPreferences.getInstance();
      final documentAccessToken = prefs.getString('document_access_token');
      if (documentAccessToken == null) {
        throw Exception('Access token dokumen tidak ditemukan');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/documents/cancel/$documentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'access_token': documentAccessToken}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        _showMessage(context, body['message'] ?? 'Permintaan dibatalkan');
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        final body = jsonDecode(response.body);
        _showMessage(context, body['message'] ?? 'Gagal membatalkan');
      }
    } catch (e) {
      _showMessage(context, 'Error: $e');
    }
  }

  /// Show snackbar message
  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
