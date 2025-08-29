import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../file/fileverifikasi.dart';
import '../upload_file/upload.dart';
import '../file/lihatsemua.dart';
import '../scan_qr/barcode_scanner_page.dart';
import 'home_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc()..add(LoadHomeData()),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is HomeError) {
            return Scaffold(body: Center(child: Text(state.message)));
          }

          if (state is HomeLoaded) {
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
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 7),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: ClipOval(
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child: Image.asset(
                                'assets/images/pp.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24.4,
                              ),
                            ),
                            Text(
                              state.role,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromRGBO(255, 255, 255, 1),
                            Color.fromRGBO(207, 207, 207, 1),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              buildButton(Icons.qr_code, 'Scan QR', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BarcodeScannerPage(),
                                  ),
                                );
                              }),
                              buildButton(Icons.upload_file, 'Upload File', () {
                                PdfPickerHelper.pickAndOpenPdf(context);
                              }),
                              buildButton(
                                Icons.verified,
                                'File Terverifikasi',
                                () {},
                              ),
                              buildButton(
                                Icons.mobile_friendly,
                                'Verifikasi TTD',
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Fileverifikasi(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Terbaru',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LihatSemuaPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Lihat Semua >',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 56, 56, 56),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      child: state.documents.isNotEmpty
                          ? Column(
                              children: state.documents.take(5).map((file) {
                                return ListTile(
                                  leading: const Icon(
                                    Icons.insert_drive_file,
                                    color: Colors.blue,
                                  ),
                                  title: Text(file['original_name'] ?? ''),
                                  subtitle: Text(
                                    'Diunggah: ${file['uploaded_at'] ?? ''}',
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {},
                                );
                              }).toList(),
                            )
                          : const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text('Belum ada dokumen yang diunggah.'),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget buildButton(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(23, 43, 76, 1),
            side: const BorderSide(color: Colors.black),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: onPressed,
          child: SizedBox(
            width: 58.97,
            height: 58.97,
            child: Center(child: Icon(icon, color: Colors.white, size: 32)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black)),
      ],
    );
  }
}
