import 'package:flutter/material.dart';
// Impor file service API Anda
import 'package:android/api/token.dart';

class ArsipDokumenPage extends StatefulWidget {
  const ArsipDokumenPage({super.key});

  @override
  State<ArsipDokumenPage> createState() => _ArsipDokumenPageState();
}

class _ArsipDokumenPageState extends State<ArsipDokumenPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> documents = [];
  List<Map<String, dynamic>> filteredDocuments = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCompletedDocuments();
  }

  Future<void> loadCompletedDocuments() async {
    final result = await fetchCompletedDocuments();
    if (mounted) {
      setState(() {
        documents = result;
        filteredDocuments = result;
        isLoading = false;
      });
    }
  }

  void filterDocuments(String query) {
    final filtered = documents.where((doc) {
      final name = (doc['original_name'] ?? '').toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredDocuments = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Dekorasi gradient tetap sama
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
            // Widget Search Bar tetap sama
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: filterDocuments,
                      decoration: const InputDecoration(
                        hintText: 'Cari di arsip...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: Colors.black),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Judul Halaman Diubah
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Arsip Dokumen Selesai', // Judul diubah
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                    : filteredDocuments.isNotEmpty
                    ? ListView.builder(
                        itemCount: filteredDocuments.length,
                        itemBuilder: (context, index) {
                          final file = filteredDocuments[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.task_alt, // Icon diubah menjadi tanda cek
                              color: Colors.green,
                            ),
                            title: Text(
                              file['original_name'] ?? 'Nama tidak tersedia',
                            ),
                            // Subtitle diubah untuk menampilkan tanggal selesai
                            subtitle: Text(
                              'Selesai pada: ${file['completed_at'] ?? 'N/A'}',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              // Tambahkan aksi, misalnya melihat detail dokumen
                            },
                          );
                        },
                      )
                    : const Center(
                        child: Text('Tidak ada dokumen yang selesai.'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
