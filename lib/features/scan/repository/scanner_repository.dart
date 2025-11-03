import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:barcode_scan2/barcode_scan2.dart';

class ScannerRepository {
  /// Melakukan scan barcode dan mengembalikan hasilnya.
  /// Melempar Exception jika terjadi kesalahan.
  Future<String> scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.rawContent.isEmpty) {
        throw Exception('Scan dibatalkan oleh pengguna');
      }
      return result.rawContent;
    } catch (e) {
      // Mengemas ulang error agar lebih konsisten
      throw Exception('Gagal melakukan scan: $e');
    }
  }

  /// Mengambil detail dokumen dari URL/token yang diberikan.
  /// Melempar Exception jika respons tidak 200.
  Future<Map<String, dynamic>> getDocumentDetail(String signToken) async {
    final response = await http.get(
      Uri.parse(signToken),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gagal mengambil detail dokumen');
    }
  }
}
