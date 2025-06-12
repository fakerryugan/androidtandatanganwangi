import 'dart:convert';
import 'dart:io';
import 'package:android/api/dokumen.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:android/api/token.dart';
import '../upload_file/menampilkanpdf.dart';

class PdfPickerHelper {
  static Future<void> pickAndOpenPdf(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      File file = File(filePath);

      try {
        String? token = await getToken();
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token tidak ditemukan. Silakan login ulang.'),
            ),
          );
          return;
        }

        var uri = Uri.parse('http://fakerryugan.my.id/api/documents/upload');
        var request = http.MultipartRequest('POST', uri);
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(await http.MultipartFile.fromPath('file', file.path));

        var response = await request.send();

        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final data = json.decode(responseBody);

          // Simpan document_id dan access_token
          await DocumentInfo.save(data['document_id'], data['access_token']);

          // Tampilkan halaman PDF Viewer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerPage(
                filePath: filePath,
                encryptedLink: data['access_token'],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal upload: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File tidak dipilih.')));
    }
  }
}
