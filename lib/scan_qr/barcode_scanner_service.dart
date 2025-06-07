import 'package:barcode_scan2/barcode_scan2.dart';

class BarcodeScannerService {
  static Future<String> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      return result.rawContent.isEmpty ? 'Scan dibatalkan' : result.rawContent;
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }
}
