import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:android/api/token.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfReviewScreen extends StatefulWidget {
  final String signToken;
  final String documentId;
  final String accessToken;

  const PdfReviewScreen({
    super.key,
    required this.signToken,
    required this.documentId,
    required this.accessToken,
  });

  @override
  State<PdfReviewScreen> createState() => _PdfReviewScreenState();
}

class _PdfReviewScreenState extends State<PdfReviewScreen> {
  String? _pdfPath;
  bool _isLoading = true;
  String? _errorMessage;
  int? _totalPages;
  int? _currentPage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/documents/review/${widget.accessToken}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/document_${widget.documentId}.pdf');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _pdfPath = file.path;
          _isLoading = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load PDF');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _processSignature(String status) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/documents/signature/${widget.signToken}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(responseData['message'])));
        Navigator.pop(context, {
          'status': status,
          'document_verified': responseData['document_verified'] ?? false,
        });
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(responseData['message'])));
        Navigator.pop(context);
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to process signature',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _confirmRejectAction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Dokumen?'),
        content: const Text('Anda yakin ingin menolak dokumen ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processSignature('rejected');
            },
            child: const Text('Tolak', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmApproveAction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui Dokumen?'),
        content: const Text('Anda yakin ingin menyetujui dokumen ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processSignature('approved');
            },
            child: const Text('Setujui', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Review Dokumen',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF172B4C),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildBottomAppBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: BottomAppBar(
        color: const Color(0xFF172B4C),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromARGB(255, 250, 250, 248),
                  border: Border.all(
                    color: const Color.fromARGB(255, 250, 250, 248),
                    width: 2,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_outlined,
                    color: Color(0xFF172B4C),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 40),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromARGB(255, 255, 6, 6),
                  border: Border.all(
                    color: const Color.fromARGB(255, 255, 6, 6),
                    width: 2,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color.fromARGB(255, 203, 203, 203),
                  ),
                  onPressed: _confirmRejectAction,
                ),
              ),
              const SizedBox(width: 40),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromARGB(255, 8, 224, 76),
                  border: Border.all(
                    color: const Color.fromARGB(255, 8, 224, 76),
                    width: 2,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.verified,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  onPressed: _confirmApproveAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loadPdf, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    if (_pdfPath == null) {
      return const Center(child: Text('Dokumen tidak tersedia'));
    }

    return Stack(
      children: [
        PDFView(
          filePath: _pdfPath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: false,
          pageFling: false,
          onRender: (pages) => setState(() => _totalPages = pages),
          onError: (error) => setState(() => _errorMessage = error.toString()),
          onPageChanged: (page, total) => setState(() {
            _currentPage = (page ?? 0) + 1;
            _totalPages = total;
          }),
        ),
        if (_currentPage != null && _totalPages != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Halaman $_currentPage/$_totalPages',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
