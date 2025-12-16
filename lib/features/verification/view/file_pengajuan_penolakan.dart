import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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

  // --- POP UP KONFIRMASI (DIPERBARUI) ---
  void _showConfirmationDialog(BuildContext context, Map<String, dynamic> doc) {
    // Ambil data tambahan
    final requestedBy = doc['diminta_batal_oleh'] ?? 'Seseorang';
    final reason = doc['alasan_pembatalan'] ?? '-';

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
              const Text("Permintaan pembatalan dokumen:"),
              const SizedBox(height: 8),
              Text(
                "\"${doc['original_name'] ?? 'File'}\"",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // --- TAMPILKAN INFO PEMBATALAN DI DIALOG ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Diminta oleh: $requestedBy",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Alasan: \"$reason\"",
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // -------------------------------------------
              const SizedBox(height: 16),
              const Text(
                "Jika Anda setuju, dokumen ini akan dihapus secara permanen untuk semua pihak.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
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

                final signToken = doc['sign_token'];

                if (signToken != null) {
                  // Kirim Event dengan Token String
                  context.read<RejectionBloc>().add(
                    ApproveRejectionDocument(signToken.toString()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Error: Token tanda tangan tidak ditemukan",
                      ),
                      backgroundColor: Colors.red,
                    ),
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
              child: const Text("Ya, Setuju"),
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

          // --- AMBIL DATA DARI RESPONSE CONTROLLER ---
          final requestedBy = doc['diminta_batal_oleh'] ?? 'N/A';
          final reason = doc['alasan_pembatalan'] ?? '-';
          // -------------------------------------------

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  child: const Icon(Icons.delete_forever, color: Colors.red),
                ),
                title: Text(
                  originalName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                // --- MODIFIKASI SUBTITLE UNTUK MENAMPILKAN ALASAN ---
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Oleh: $requestedBy",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Alasan: $reason",
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // ----------------------------------------------------
                trailing: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  _showConfirmationDialog(context, doc);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: BlocConsumer<RejectionBloc, RejectionState>(
                  listener: (context, state) {
                    if (state is RejectionActionSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (state is RejectionActionFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Gagal: ${state.error}"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
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
                                      Icons.check_circle_outline,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Tidak ada permintaan pembatalan.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return _buildRejectionList(
                        blocContext,
                        state.filteredDocuments,
                      );
                    }

                    return const Center(child: CircularProgressIndicator());
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
