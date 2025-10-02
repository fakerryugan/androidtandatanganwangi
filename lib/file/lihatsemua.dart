import 'package:android/api/token.dart';
import 'package:flutter/material.dart';

class LihatSemuaPage extends StatefulWidget {
  const LihatSemuaPage({super.key});

  @override
  State<LihatSemuaPage> createState() => _LihatSemuaPageState();
}

class _LihatSemuaPageState extends State<LihatSemuaPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> documents = [];

  @override
  void initState() {
    super.initState();
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    final result = await fetchUserDocuments();
    setState(() {
      documents = result;
      isLoading = false;
    });
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
                        'assets/images/pp.png',
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
                            ),
                            subtitle: Text(
                              'Diunggah: ${file['uploaded_at'] ?? ''}',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {},
                          );
                        },
                      )
                    : const Center(
                        child: Text('Belum ada dokumen yang diunggah.'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
