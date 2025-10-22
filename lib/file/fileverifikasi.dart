import 'package:android/verifikasi/verifikasi.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:android/api/token.dart';

class Fileverifikasi extends StatefulWidget {
  const Fileverifikasi({super.key});

  @override
  State<Fileverifikasi> createState() => _FileverifikasiState();
}

class _FileverifikasiState extends State<Fileverifikasi> {
  bool isLoading = true;
  List<Map<String, dynamic>> documents = [];
  List<Map<String, dynamic>> _filteredDocuments = [];
  String errorMessage = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _muatDokumen();
  }

  Future<void> _muatDokumen() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/signature/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            documents = List<Map<String, dynamic>>.from(data['documents']);
            _filteredDocuments = documents;
            errorMessage = '';
          });
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat dokumen');
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: ${e.toString()}';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterDocuments(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredDocuments = documents
          .where(
            (doc) => (doc['original_name'] ?? '').toLowerCase().contains(
              _searchQuery,
            ),
          )
          .toList();
    });
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 50,
              height: 50,
              child: Image.asset('assets/images/pp.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: _filterDocuments,
              decoration: const InputDecoration(
                hintText: 'Cari file...',
                border: InputBorder.none,
              ),
            ),
          ),
          const Icon(Icons.search, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Dokumen Perlu Verifikasi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList() {
    return RefreshIndicator(
      onRefresh: _muatDokumen,
      child: ListView.builder(
        itemCount: _filteredDocuments.length,
        itemBuilder: (context, index) {
          final doc = _filteredDocuments[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: Text(doc['original_name'] ?? 'Dokumen Tanpa Nama'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tanggal: ${doc['uploaded_at'] ?? '-'}'),
                  Text('Tujuan: ${doc['tujuan'] ?? '-'}'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => _tampilkanDialogVerifikasi(context, doc),
            ),
          );
        },
      ),
    );
  }

  void _tampilkanDialogVerifikasi(
    BuildContext context,
    Map<String, dynamic> doc,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc['original_name'] ?? 'Verifikasi Dokumen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tanggal: ${doc['uploaded_at'] ?? '-'}'),
            const SizedBox(height: 10),
            Text('Tujuan: ${doc['tujuan'] ?? '-'}'),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                final dynamic signTokenRaw = doc['sign_token'];
                final dynamic accessTokenRaw = doc['access_token'];
                final dynamic documentIdRaw = doc['document_id'];

                final String? signToken = signTokenRaw != null
                    ? signTokenRaw.toString()
                    : null;
                final String? accessToken = accessTokenRaw != null
                    ? accessTokenRaw.toString()
                    : null;
                final String? documentId = documentIdRaw != null
                    ? documentIdRaw.toString()
                    : null;

                if (signToken == null ||
                    signToken.isEmpty ||
                    accessToken == null ||
                    accessToken.isEmpty ||
                    documentId == null ||
                    documentId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Data dokumen tidak lengkap. Tidak dapat membuka review.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfReviewScreen(
                      signToken: signToken,
                      accessToken: accessToken,
                      documentId: documentId,
                    ),
                  ),
                );
              },
              child: const Text(
                'Lihat Dokumen Lengkap',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
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
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildHeader(),
            const SizedBox(height: 12),
            _buildSectionTitle(),
            Expanded(
              child: Container(
                color: Colors.white,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage.isNotEmpty
                    ? Center(child: Text(errorMessage))
                    : _filteredDocuments.isNotEmpty
                    ? _buildDocumentList()
                    : const Center(child: Text('Tidak ada dokumen')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
