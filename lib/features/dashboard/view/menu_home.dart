import 'package:android/features/file/view/lihatsemuapage.dart';
import 'package:android/features/file/view/arsipdokumen.dart';
import 'package:android/features/scan/view/scanner_page.dart';
import 'package:android/features/verification/view/file_pengajuan_main_page.dart';

import 'package:android/features/verification/view/fileverifikasipage.dart';
import 'package:android/upload_file/upload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';

class MenuHome extends StatelessWidget {
  const MenuHome({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is DashboardError) {
          return Scaffold(body: Center(child: Text(state.message)));
        }
        if (state is DashboardLoaded) {
          return Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: false,
                  floating: false,
                  expandedHeight: 230,
                  backgroundColor: const Color.fromARGB(0, 126, 29, 29),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
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
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Bagian Profil
                              Row(
                                children: [
                                  const SizedBox(width: 16),
                                  ClipOval(
                                    child: SizedBox(
                                      width: 70,
                                      height: 70,
                                      child: Image.asset(
                                        'assets/images/pp.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) =>
                                            const Icon(Icons.person, size: 70),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.name, // Dari state baru
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24.4,
                                        ),
                                      ),
                                      Text(
                                        state.role, // Dari state baru
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Bagian Tombol Aksi Utama - DIUBAH MENJADI PLACEHOLDER SEMENTARA
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  30,
                                ),
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
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: buildButton(
                                        Icons.qr_code,
                                        'Scan QR',
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BarcodeScannerPage(),
                                            ),
                                          );
                                        },
                                        key: const Key(
                                          'scan_qr_button',
                                        ), // <-- TAMBAHKAN INI
                                      ),
                                    ),
                                    Expanded(
                                      child: buildButton(
                                        Icons.upload_file,
                                        'Upload File',
                                        () {
                                          PdfPickerHelper.pickAndOpenPdf(
                                            context,
                                          );
                                        },
                                        key: const Key('upload_file_button'),
                                      ),
                                    ),
                                    Expanded(
                                      child: buildButton(
                                        Icons.verified,
                                        'Status File',
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ArsipDokumenPage(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: buildButton(
                                        Icons.mobile_friendly,
                                        'Pengajuan',
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FileReviewMainPage(),
                                            ),
                                          );
                                        },
                                        key: const Key('verifikasi_ttd_button'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Bagian Daftar Terbaru
                SliverList(
                  delegate: SliverChildListDelegate([
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
                              {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LihatSemuaPage(),
                                  ),
                                );
                              }
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
                    if (state.documents.isNotEmpty)
                      ...state.documents.map((file) {
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
                      })
                    else
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text('Belum ada dokumen yang diunggah.'),
                        ),
                      ),
                  ]),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // Fungsi buildButton (widget pembangun tombol) masih disimpan,
  // tetapi tidak digunakan di dalam `build` di bagian aksi utama.
  Widget buildButton(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    Key? key,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          key: key,
          style: OutlinedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(23, 43, 76, 1),
            side: const BorderSide(color: Colors.black),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            fixedSize: const Size(60, 60), // tetap kotak
            padding: EdgeInsets.zero,
          ),
          onPressed: onPressed,
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 30,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}
