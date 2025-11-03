// lib/features/arsip/view/arsip_dokumen_page.dart

import 'package:android/features/filereview/view/pdf_archive_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/tokenapi.dart';
import '../repository/files_repository.dart';
import '../bloc/files_bloc.dart';

class ArsipDokumenPage extends StatelessWidget {
  const ArsipDokumenPage({super.key});

  // --- FUNGSI HELPER UNTUK FORMAT TANGGAL ---
  String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      // Menggunakan format dd MMM yyyy, HH:mm (contoh: 03 Nov 2025, 14:30)
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (_) {
      return dateStr; // Kembalikan string asli jika format tidak valid
    }
  }

  // --- FUNGSI UNTUK MENAMPILKAN DIALOG OPSI ---
  void _showOptionsDialog(BuildContext context, Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(file['original_name'] ?? 'Pilih Aksi'),
          content: const Text(
            'Apa yang ingin Anda lakukan dengan dokumen ini?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Download'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
                _downloadFile(context, file); // Panggil fungsi download
              },
            ),
            TextButton(
              child: const Text('Review'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
                _reviewFile(context, file); // Panggil fungsi review
              },
            ),
          ],
        );
      },
    );
  }

  // --- FUNGSI UNTUK AKSI DOWNLOAD ---
  void _downloadFile(BuildContext context, Map<String, dynamic> file) async {
    // Cek status izin
    var status = await Permission.manageExternalStorage.status;

    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin Akses Penyimpanan ditolak. Download dibatalkan.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Lanjutkan proses download jika izin sudah diberikan
    final accessToken = file['access_token'] as String?;
    final encryptedName = file['encrypted_original_filename'] as String?;
    final originalName = file['original_name'] as String?;

    if (accessToken == null || encryptedName == null || originalName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data dokumen tidak lengkap untuk diunduh.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mulai mengunduh "$originalName"...'),
        backgroundColor: Colors.blue,
      ),
    );

    context.read<FilesBloc>().add(
      DownloadFile(
        accessToken: accessToken,
        encryptedName: encryptedName,
        originalName: originalName,
      ),
    );
  }

  // --- FUNGSI UNTUK AKSI REVIEW (YANG SUDAH DIPERBARUI) ---
  void _reviewFile(BuildContext context, Map<String, dynamic> file) {
    // Ambil data yang diperlukan dari map 'file'
    final accessToken = file['access_token'] as String?;
    final encryptedName = file['encrypted_original_filename'] as String?;
    final originalName = file['original_name'] as String?;

    // Validasi data sebelum navigasi
    if (accessToken == null || encryptedName == null || originalName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data dokumen tidak lengkap untuk direview.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigasi ke halaman review PDF yang baru
    Navigator.push(
      context,
      MaterialPageRoute(
        // Kita teruskan instance FilesBloc ke halaman baru menggunakan BlocProvider.value
        // agar tombol download di sana bisa berfungsi dengan baik.
        builder: (_) => BlocProvider.value(
          value: BlocProvider.of<FilesBloc>(context),
          child: PdfArchiveReviewScreen(
            accessToken: accessToken,
            encryptedName: encryptedName,
            originalName: originalName,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          FilesBloc(repository: FilesRepository(apiService: ApiServiceImpl()))
            ..add(LoadCompletedFiles()),
      child: BlocListener<FilesBloc, FilesState>(
        listener: (context, state) {
          // Tampilkan notifikasi saat download berhasil atau gagal
          if (state is FileDownloadSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
          } else if (state is FileDownloadFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
          }
        },
        child: Scaffold(
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
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (query) {
                              context.read<FilesBloc>().add(SearchFiles(query));
                            },
                            decoration: const InputDecoration(
                              hintText: 'Cari di arsip...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                          ),
                        ),
                        const Icon(Icons.search, color: Colors.black),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Section Title
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Arsip Dokumen Selesai',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Document List
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      width: double.infinity,
                      child: BlocBuilder<FilesBloc, FilesState>(
                        builder: (context, state) {
                          if (state is FilesLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state is FilesError) {
                            return Center(child: Text(state.message));
                          }
                          if (state is FilesLoaded) {
                            if (state.filteredDocuments.isEmpty) {
                              return RefreshIndicator(
                                onRefresh: () async {
                                  context.read<FilesBloc>().add(
                                    LoadCompletedFiles(),
                                  );
                                },
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(50.0),
                                      child: Center(
                                        child: Text(
                                          'Tidak ada dokumen yang selesai.',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return RefreshIndicator(
                              onRefresh: () async {
                                context.read<FilesBloc>().add(
                                  LoadCompletedFiles(),
                                );
                              },
                              child: ListView.builder(
                                itemCount: state.filteredDocuments.length,
                                itemBuilder: (context, index) {
                                  final file = state.filteredDocuments[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.task_alt,
                                        color: Colors.green,
                                      ),
                                      title: Text(
                                        file['original_name'] ??
                                            'Nama tidak tersedia',
                                      ),
                                      subtitle: Text(
                                        'Selesai pada: ${formatDate(file['completed_at'])}',
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        _showOptionsDialog(context, file);
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
