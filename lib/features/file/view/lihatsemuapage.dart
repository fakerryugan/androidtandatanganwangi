import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/tokenapi.dart';
import '../repository/files_repository.dart';
import '../bloc/files_bloc.dart';
import 'package:intl/intl.dart'; // Impor intl untuk format tanggal

class LihatSemuaPage extends StatelessWidget {
  const LihatSemuaPage({super.key});

  // --- FUNGSI HELPER UNTUK FORMAT TANGGAL ---
  String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sediakan BLoC baru ke widget tree halaman ini
    return BlocProvider(
      create: (context) =>
          FilesBloc(repository: FilesRepository(apiService: ApiServiceImpl()))
            ..add(LoadAllFiles()), // Muat semua file saat halaman dibuka
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
          // --- PENAMBAHAN SAFEAREA ---
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Search bar sekarang mengambil event BLoC
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
                            // Kirim event search ke BLoC
                            context.read<FilesBloc>().add(SearchFiles(query));
                          },
                          decoration: const InputDecoration(
                            hintText: 'Cari semua file...',
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Semua Dokumen',
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    width: double.infinity,
                    // Gunakan BlocBuilder untuk menampilkan state
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
                                context.read<FilesBloc>().add(LoadAllFiles());
                              },
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(50.0),
                                    child: Center(
                                      child: Text('Dokumen tidak ditemukan.'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          // Build list dari filteredDocuments
                          return RefreshIndicator(
                            onRefresh: () async {
                              context.read<FilesBloc>().add(LoadAllFiles());
                            },
                            child: ListView.builder(
                              itemCount: state.filteredDocuments.length,
                              itemBuilder: (context, index) {
                                final file = state.filteredDocuments[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.insert_drive_file,
                                    color: Colors.blue,
                                  ),
                                  title: Text(
                                    file['original_name'] ??
                                        'Nama tidak tersedia',
                                  ),
                                  subtitle: Text(
                                    // Gunakan helper formatDate
                                    'Diunggah: ${formatDate(file['uploaded_at'])}',
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    // TODO: Tentukan aksi saat item di-tap
                                    // Mungkin tampilkan dialog seperti di ArsipDokumenPage?
                                    // _showOptionsDialog(context, file);
                                  },
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
    );
  }
}
