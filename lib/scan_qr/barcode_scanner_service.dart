import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BarcodeScannerService {
  static Future<String> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      return result.rawContent.isEmpty ? 'Scan dibatalkan' : result.rawContent;
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

  static Future<Map<String, dynamic>> DocumentDetail(String signToken) async {
    final response = await http.get(
      Uri.parse(signToken),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Gagal mengambil data');
    }
  }
}
