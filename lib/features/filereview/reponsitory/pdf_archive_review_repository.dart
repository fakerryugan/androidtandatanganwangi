// lib/features/arsip/repository/pdf_archive_review_repository.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart'; // <-- 1. IMPORT PACKAGE CRYPTO
import '../../../core/services/tokenapi.dart'; // Pastikan path ini benar

class PdfArchiveReviewRepository {
  Future<File> loadArchivePdf(String accessToken, String encryptedName) async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    // Pastikan URL endpoint ini sudah benar!
    final response = await http.post(
      Uri.parse('$baseUrl/documents/review/$accessToken'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/pdf'},
    );

    if (response.statusCode == 200) {
      // --- PERBAIKAN UTAMA ADA DI SINI ---

      // 2. Buat ID pendek dari encryptedName menggunakan hash MD5
      // Pola ini sama seperti menggunakan documentId yang pendek.
      final bytes = utf8.encode(encryptedName);
      final digest = md5.convert(bytes);
      final shortUniqueId = digest.toString();

      final dir = await getTemporaryDirectory();

      // 3. Gunakan ID pendek yang unik untuk nama file
      final file = File('${dir.path}/$shortUniqueId.pdf');

      print('Saving PDF to: ${file.path}');

      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      print('Gagal memuat PDF. Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal memuat PDF');
      } catch (_) {
        throw Exception('Gagal memuat PDF. Status: ${response.statusCode}');
      }
    }
  }
}
