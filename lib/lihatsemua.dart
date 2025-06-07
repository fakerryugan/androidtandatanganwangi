import 'package:android/api/datadokumen.dart';
import 'package:flutter/material.dart';

// ignore: camel_case_types
class lihatsemuapage extends StatelessWidget {
  const lihatsemuapage({super.key});

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
                children: [
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
                child: dummyFiles.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada file terbaru',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: dummyFiles.length,
                        itemBuilder: (context, index) {
                          final file = dummyFiles[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.insert_drive_file,
                              color: Colors.blue,
                            ),
                            title: Text(file['nama']!),
                            subtitle: Text('Diunggah: ${file['tanggal']}'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {},
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
