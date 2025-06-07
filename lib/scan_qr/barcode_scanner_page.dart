import 'package:android/scan_qr/barcode_scanner_service.dart';
import 'package:flutter/material.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  String result = 'Belum scan';

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    final scanResult = await BarcodeScannerService.scanBarcode();
    setState(() {
      result = scanResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hasil Scan")),
      body: Center(child: Text(result)),
    );
  }
}
