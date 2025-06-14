import 'package:android/scan_qr/barcode_scanner_service.dart';
import 'package:flutter/material.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  Map<String, dynamic>? documentData;
  String statusMessage = 'Memulai scan...';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    final scanResult = await BarcodeScannerService.scanBarcode();

    if (scanResult.startsWith('http')) {
      try {
        final signToken = Uri.parse(scanResult).pathSegments.last;
        final data = await BarcodeScannerService.fetchDocumentDetail(signToken);
        setState(() {
          documentData = data;
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          statusMessage = 'Gagal mengambil detail: $e';
          isLoading = false;
        });
      }
    } else {
      setState(() {
        statusMessage = scanResult;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(127, 146, 248, 1),
              Color.fromRGBO(175, 219, 248, 1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 87,
                    height: 86,
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SELAMAT DATANG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'APLIKASI DOKUMEN & TANDA TANGAN DIGITAL',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'POLITEKNIK NEGERI BANYUWANGI',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  _buildResultBox(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBox() {
    if (isLoading) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    if (documentData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Text(
          statusMessage,
          style: const TextStyle(color: Colors.black),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Judul', documentData!['original_name']),
          const SizedBox(height: 8),
          _buildInfoRow('Diajukan Kepada', documentData!['tujuan']),
          const SizedBox(height: 8),
          _buildInfoRow('Status', documentData!['status']),
          const SizedBox(height: 8),
          _buildInfoRow('Signer ID', documentData!['signer_id'].toString()),
          const SizedBox(height: 8),
          _buildInfoRow('Download URL', documentData!['download_url']),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return RichText(
      text: TextSpan(
        text: '$label: ',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 14,
        ),
        children: [
          TextSpan(
            text: value ?? '-',
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
