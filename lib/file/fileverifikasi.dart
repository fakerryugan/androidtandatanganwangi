import 'package:android/api/token.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Fileverifikasi extends StatefulWidget {
  const Fileverifikasi({super.key});

  @override
  State<Fileverifikasi> createState() => _Fileverifikasi();
}

class _Fileverifikasi extends State<Fileverifikasi> {
  bool isLoading = true;
  List<Map<String, dynamic>> documents = [];

  @override
  void initState() {
    super.initState();
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/signatures/user'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List docs = data['documents'];
        setState(() {
          documents = docs.map((e) => e as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat dokumen');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              Color.fromRGBO(127, 146, 248, 1),
              Color.fromRGBO(175, 219, 248, 1),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
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
                      child: Image.asset(
                        'assets/images/pp.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Cari file',
                    style: TextStyle(fontSize: 15, color: Colors.black),
                  ),
                  const Spacer(),
                  const Icon(Icons.person, size: 40, color: Colors.black),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Terbaru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                width: double.infinity,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : documents.isNotEmpty
                    ? ListView.builder(
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final file = documents[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.insert_drive_file,
                              color: Colors.blue,
                            ),
                            title: Text(
                              file['original_name'] ?? 'Nama tidak tersedia',
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Diunggah: ${file['uploaded_at'] ?? ''}\nTujuan: ${file['tujuan'] ?? "-"}',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DummySignPage(
                                    documentId: file['document_id'],
                                    signToken: file['sign_token'],
                                    accessToken: file['access_token'],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                    : const Center(
                        child: Text('Belum ada dokumen untuk diverifikasi.'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DummySignPage extends StatelessWidget {
  final int documentId;
  final String signToken;
  final String accessToken;

  const DummySignPage({
    super.key,
    required this.documentId,
    required this.signToken,
    required this.accessToken,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tanda Tangan Dokumen')),
      body: Center(
        child: Text(
          'Dokumen ID: $documentId\nSign Token: $signToken\nAccess Token: $accessToken',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
