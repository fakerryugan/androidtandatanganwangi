import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

// Pastikan import ini mengarah ke BLoC Rejection Anda
import '../bloc/rejection_bloc.dart';

class FilePenolakanPage extends StatelessWidget {
  const FilePenolakanPage({super.key});

  // --- HELPER FORMAT TANGGAL ---
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  // --- POP UP KONFIRMASI ---
  void _showConfirmationDialog(BuildContext context, Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Setujui Penghapusan?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Apakah Anda yakin ingin menyetujui permintaan ini?"),
              const SizedBox(height: 8),
              Text(
                "Dokumen \"${doc['original_name'] ?? 'File'}\" akan dihapus secara permanen.",
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Tutup dialog

                final documentId = doc['id'] ?? doc['document_id'];
                if (documentId != null) {
                  context.read<RejectionBloc>().add(
                    ApproveRejectionDocument(documentId),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Memproses persetujuan...")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Setuju & Hapus"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRejectionList(
    BuildContext context,
    List<Map<String, dynamic>> documents,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<RejectionBloc>().add(LoadRejectionDocuments());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        itemBuilder: (itemContext, index) {
          final doc = documents[index];
          final originalName = doc['original_name'] ?? 'Dokumen Tanpa Nama';
          final uploadDate = _formatDate(doc['uploaded_at']);

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
              leading: CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.1),
                child: const Icon(Icons.delete_forever, color: Colors.red),
              ),
              title: Text(
                originalName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Diajukan: $uploadDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
              onTap: () {
                // Panggil Pop Up Konfirmasi saat diklik
                _showConfirmationDialog(context, doc);
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan Builder untuk memastikan context aman (dapat mengakses Provider)
    return Builder(
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<RejectionBloc, RejectionState>(
                  builder: (blocContext, state) {
                    if (state is RejectionLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is RejectionError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
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
                                'Gagal memuat data:\n${state.message}',
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: () {
                                  blocContext.read<RejectionBloc>().add(
                                    LoadRejectionDocuments(),
                                  );
                                },
                                child: const Text("Coba Lagi"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is RejectionLoaded) {
                      if (state.filteredDocuments.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            blocContext.read<RejectionBloc>().add(
                              LoadRejectionDocuments(),
                            );
                          },
                          child: ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Tidak ada pengajuan penolakan.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      // Tampilkan List
                      return _buildRejectionList(
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
