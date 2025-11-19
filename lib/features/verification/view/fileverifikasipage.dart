import 'package:android/features/verification/view/VerificationDetailDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Pastikan package ini ada
import '../bloc/verification_bloc.dart';
import 'package:android/features/filereviewverification/view/pdf_review_screen.dart';

// PENTING: Pastikan import file dialog yang Anda berikan tadi.
// Jika file dialog bernama 'verification_detail_dialog.dart', uncomment baris di bawah:
// import 'verification_detail_dialog.dart';

// Jika Anda menaruh class Dialog di file yang sama (paling bawah), import tidak perlu.

class FileVerifikasiPage extends StatelessWidget {
  const FileVerifikasiPage({super.key});

  // --- BAGIAN BARU: Menampilkan Dialog ---
  void _showDetailDialog(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        // Pastikan class VerificationDetailDialog sudah ada/diimport
        return VerificationDetailDialog(
          file: doc,

          // LOGIC PENTING:
          // Saat tombol 'Review' di dialog ditekan, jalankan fungsi navigasi ini
          onReview: () {
            _navigateToDetailAndRefresh(context, doc);
          },
        );
      },
    );
  }

  // Fungsi Navigasi ke Layar PDF (Logic Lama Anda)
  void _navigateToDetailAndRefresh(
    BuildContext context,
    Map<String, dynamic> doc,
  ) async {
    // Ambil data dengan aman
    final signToken = doc['sign_token'];
    final accessToken = doc['access_token'];
    final documentId = doc['document_id']?.toString() ?? doc['id']?.toString();

    if (documentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ID Dokumen tidak ditemukan")),
      );
      return;
    }

    // Pindah ke Screen Review
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfReviewScreen(
          signToken: signToken,
          accessToken: accessToken,
          documentId: documentId,
        ),
      ),
    );

    // Refresh saat kembali
    if (context.mounted) {
      context.read<VerificationBloc>().add(LoadVerificationDocuments());
    }
  }

  Widget _buildDocumentList(
    BuildContext context,
    List<Map<String, dynamic>> documents,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<VerificationBloc>().add(LoadVerificationDocuments());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        itemBuilder: (itemContext, index) {
          final doc = documents[index];

          // Persiapan Data Tampilan
          final title = doc['original_name'] ?? 'Dokumen Tanpa Nama';
          final date = doc['uploaded_at'] ?? '-';
          final tujuan = doc['tujuan_surat'] ?? doc['tujuan'] ?? '-';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                    255,
                    127,
                    146,
                    248,
                  ).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description,
                  color: Color.fromARGB(255, 127, 146, 248),
                ),
              ),
              title: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Tanggal: $date', style: const TextStyle(fontSize: 12)),
                  Text('Tujuan: $tujuan', style: const TextStyle(fontSize: 12)),
                ],
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),

              // PERUBAHAN DI SINI:
              // Sekarang onTap memanggil _showDetailDialog, BUKAN langsung navigasi
              onTap: () => _showDetailDialog(context, {
                ...doc, // Copy semua data asli
                // Pastikan key ini ada agar tidak null saat dikirim ke PDF Screen
                'sign_token': doc['sign_token'] ?? '',
                'access_token': doc['access_token'] ?? '',
                'document_id': doc['id'] ?? doc['document_id'],
              }),
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext newContext) {
        return Scaffold(
          backgroundColor: Colors.transparent, // Sesuaikan background
          body: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<VerificationBloc, VerificationState>(
                  builder: (blocContext, state) {
                    if (state is VerificationLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is VerificationError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Terjadi Kesalahan:\n${state.message}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => blocContext
                                  .read<VerificationBloc>()
                                  .add(LoadVerificationDocuments()),
                              child: const Text("Coba Lagi"),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is VerificationLoaded) {
                      if (state.filteredDocuments.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            blocContext.read<VerificationBloc>().add(
                              LoadVerificationDocuments(),
                            );
                          },
                          child: ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.folder_open,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Tidak ada dokumen untuk diverifikasi.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return _buildDocumentList(
                        blocContext,
                        state.filteredDocuments,
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
