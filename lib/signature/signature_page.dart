import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:signature/signature.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../file_viewer/signed_files_viewer.dart';

enum SignatureType { manual, qrCode }

class SignaturePage extends StatefulWidget {
  const SignaturePage({super.key});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage>
    with TickerProviderStateMixin {
  late SignatureController _signatureController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  File? _selectedPdfFile;
  String? _signatureName;
  bool _isLoading = false;
  Uint8List? _signatureImage;
  SignatureType _selectedSignatureType = SignatureType.manual;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
      onDrawStart: () {},
      onDrawEnd: () {},
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _loadUserInfo();
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final userMap = jsonDecode(userString);
      setState(() {
        _signatureName = userMap['name'] ?? 'Pengguna';
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPdfFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _captureSignature() async {
    if (_signatureController.isEmpty) {
      _showSnackBar('Silakan buat tanda tangan terlebih dahulu!');
      return;
    }

    try {
      final Uint8List? data = await _signatureController.toPngBytes();
      if (data != null && data.isNotEmpty) {
        setState(() {
          _signatureImage = data;
        });
        _showSnackBar('Tanda tangan berhasil disimpan!', isError: false);
      } else {
        _showSnackBar('Gagal menyimpan tanda tangan. Coba lagi!');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<String> _generateQRCodeData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    final userMap = userString != null ? jsonDecode(userString) : {};

    final qrData = {
      'user_id': userMap['id'] ?? 'unknown',
      'name': userMap['name'] ?? 'Pengguna',
      'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'document': _selectedPdfFile?.path.split('/').last ?? 'unknown',
    };

    return jsonEncode(qrData);
  }

  Future<void> _signAndSaveDocument() async {
    if (_selectedPdfFile == null) {
      _showSnackBar('Pilih file PDF terlebih dahulu!');
      return;
    }

    if (_selectedSignatureType == SignatureType.manual) {
      if (_signatureController.isEmpty) {
        _showSnackBar('Buat tanda tangan terlebih dahulu!');
        return;
      }
      if (_signatureImage == null) {
        await _captureSignature();
        if (_signatureImage == null) return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pdf = pw.Document();

      if (_selectedSignatureType == SignatureType.manual) {
        final signatureImg = pw.MemoryImage(_signatureImage!);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Dokumen Ditandatangani',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('File: ${_selectedPdfFile!.path.split('/').last}'),
                  pw.Text('Ditandatangani oleh: $_signatureName'),
                  pw.Text(
                    'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'Tanda Tangan:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Image(signatureImg, width: 200, height: 100),
                ],
              );
            },
          ),
        );
      } else {
        final qrCodeData = await _generateQRCodeData();

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Dokumen Ditandatangani dengan QR Code',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('File: ${_selectedPdfFile!.path.split('/').last}'),
                  pw.Text('Ditandatangani oleh: $_signatureName'),
                  pw.Text(
                    'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text(
                    'QR Code Verifikasi:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: 150,
                    height: 150,
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Center(
                      child: pw.Text(
                        'QR CODE\n${qrCodeData.substring(0, 50)}...',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Data QR Code: $qrCodeData',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              );
            },
          ),
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final signatureType = _selectedSignatureType == SignatureType.manual
          ? 'manual'
          : 'qr';
      final file = File(
        '${directory.path}/signed_document_${signatureType}_$timestamp.pdf',
      );

      await file.writeAsBytes(await pdf.save());

      _showSuccessDialog(file.path);
    } catch (e) {
      _showSnackBar('Gagal menyimpan dokumen: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String filePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                spreadRadius: 5,
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 20),
              const Text(
                'Berhasil!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Dokumen berhasil ditandatangani dengan ${_selectedSignatureType == SignatureType.manual ? 'tanda tangan manual' : 'QR Code'}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        filePath.split('/').last,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignedFilesViewerPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Lihat File'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _selectedPdfFile = null;
                          _signatureImage = null;
                          _signatureController.clear();
                        });
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('OK'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearSignature() {
    _signatureController.clear();
    setState(() {
      _signatureImage = null;
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '✍️ Tanda Tangan Digital',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(127, 146, 248, 1),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memproses dokumen...'),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SlideTransition(
                      position: _slideAnimation,
                      child: _buildSignatureTypeSelector(),
                    ),
                    const SizedBox(height: 20),

                    SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _slideController,
                              curve: const Interval(0.2, 1.0),
                            ),
                          ),
                      child: _buildPdfSelector(),
                    ),
                    const SizedBox(height: 20),

                    SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _slideController,
                              curve: const Interval(0.4, 1.0),
                            ),
                          ),
                      child: _buildSignatureArea(),
                    ),
                    const SizedBox(height: 30),

                    SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _slideController,
                              curve: const Interval(0.6, 1.0),
                            ),
                          ),
                      child: _buildActionButtons(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSignatureTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromRGBO(127, 146, 248, 1),
            Color.fromRGBO(175, 219, 248, 1),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.touch_app, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Pilih Jenis Tanda Tangan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildSignatureTypeOption(
                  SignatureType.manual,
                  Icons.edit,
                  'Tanda Tangan\nManual',
                  'Tulis langsung dengan jari',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSignatureTypeOption(
                  SignatureType.qrCode,
                  Icons.qr_code,
                  'QR Code\nDigital',
                  'Generate QR Code otomatis',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureTypeOption(
    SignatureType type,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = _selectedSignatureType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSignatureType = type;
          if (type == SignatureType.qrCode) {
            _signatureImage = null;
            _signatureController.clear();
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? const Color.fromRGBO(127, 146, 248, 1)
                  : Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected
                    ? const Color.fromRGBO(127, 146, 248, 1)
                    : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.grey : Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text(
                'Dokumen PDF',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_selectedPdfFile != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedPdfFile!.path.split('/').last,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickPdf,
              icon: Icon(
                _selectedPdfFile != null ? Icons.refresh : Icons.upload_file,
              ),
              label: Text(
                _selectedPdfFile != null ? 'Ganti PDF' : 'Pilih File PDF',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF172B4C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureArea() {
    if (_selectedSignatureType == SignatureType.qrCode) {
      return _buildQRCodeArea();
    } else {
      return _buildManualSignatureArea();
    }
  }

  Widget _buildManualSignatureArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.draw, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                'Area Tanda Tangan Manual',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Signature(
              controller: _signatureController,
              height: 200,
              backgroundColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tanda tangan dengan jari di area di atas',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clearSignature,
                  icon: const Icon(Icons.clear),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _captureSignature,
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code, color: Colors.purple, size: 24),
              SizedBox(width: 8),
              Text(
                'QR Code Digital',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data:
                        'QR_CODE_PREVIEW_${_signatureName}_${DateTime.now().millisecondsSinceEpoch}',
                    version: QrVersions.auto,
                    size: 150.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'QR Code akan digenerate otomatis saat menandatangani dokumen',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Penandatangan: $_signatureName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172B4C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    bool canSign =
        _selectedPdfFile != null &&
        (_selectedSignatureType == SignatureType.qrCode ||
            (_selectedSignatureType == SignatureType.manual &&
                !_signatureController.isEmpty));

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedPdfFile = null;
                  _signatureImage = null;
                  _signatureController.clear();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey,
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: canSign ? _signAndSaveDocument : null,
              icon: const Icon(Icons.save),
              label: const Text('Tandatangani Dokumen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: canSign
                    ? const Color.fromRGBO(127, 146, 248, 1)
                    : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: canSign ? 3 : 0,
                shadowColor: Colors.blue.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
