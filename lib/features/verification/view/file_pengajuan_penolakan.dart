import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/rejection_bloc.dart'; // Import BLoC yang baru

class FilePenolakanPage extends StatelessWidget {
  const FilePenolakanPage({super.key});

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 230, 230, 230),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            // Gunakan context yang memiliki BLoC
            child: TextField(
              onChanged: (query) {
                context.read<RejectionBloc>().add(
                  SearchRejectionDocuments(query),
                );
              },
              decoration: const InputDecoration(
                hintText: 'Cari file penolakan...',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionList(
    BuildContext context, // Context dari BlocBuilder
    List<Map<String, dynamic>> documents,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        // Panggil BLoC untuk me-refresh data
        context.read<RejectionBloc>().add(LoadRejectionDocuments());
      },
      child: ListView.builder(
        itemCount: documents.length,
        itemBuilder: (itemContext, index) {
          final doc = documents[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: const Icon(
                Icons.description,
                color: Color.fromARGB(255, 127, 146, 248),
              ),
              title: Text(doc['original_name'] ?? 'Dokumen Tanpa Nama'),
              // Sesuaikan subtitle dengan data yang relevan dari API
              subtitle: Text(
                'Tanggal: ${doc['uploaded_at'] ?? 'Tanggal tidak tersedia'}',
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // TODO: Navigasi ke halaman detail penolakan
                // Di sana Anda bisa memanggil API 'approveCancellation'
                ScaffoldMessenger.of(itemContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Detail Pengajuan Penolakan: ${doc['original_name']}',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Kirim context yang memiliki RejectionBloc
          _buildSearchBar(context),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<RejectionBloc, RejectionState>(
              builder: (blocContext, state) {
                if (state is RejectionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is RejectionError) {
                  return Center(
                    child: Text(
                      'Terjadi Kesalahan: ${state.message}',
                      textAlign: TextAlign.center,
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
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(50.0),
                              child: Text(
                                'Tidak ada dokumen pengajuan penolakan.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  // Kirim blocContext ke list
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
  }
}
