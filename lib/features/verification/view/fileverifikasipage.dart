import 'package:android/features/filereviewverification/view/pdf_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/verification_bloc.dart';
// Sesuaikan path import di atas jika perlu

class FileVerifikasiPage extends StatelessWidget {
  const FileVerifikasiPage({super.key});

  // PERBAIKAN 1: _buildSearchBar disederhanakan.
  // Tidak perlu 'Builder' internal lagi karena 'context' yang
  // diteruskan dari 'build' utama sekarang sudah valid.

  // Widget ini sudah benar (menggunakan context dari BlocBuilder)
  Widget _buildDocumentList(
    BuildContext context, // Context ini berasal dari BlocBuilder (Aman)
    List<Map<String, dynamic>> documents,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        // context di sini (dari BlocBuilder) sudah benar
        context.read<VerificationBloc>().add(LoadVerificationDocuments());
      },
      child: ListView.builder(
        itemCount: documents.length,
        itemBuilder: (itemContext, index) {
          // itemContext: context per ListTile
          final doc = documents[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: const Icon(
                Icons.description,
                color: Color.fromARGB(255, 127, 146, 248),
              ),
              title: Text(doc['original_name'] ?? 'Dokumen Tanpa Nama'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal: ${doc['uploaded_at'] ?? '07 - 12 - 2025, 20:12 WIB'}',
                  ),
                  Text('Tujuan: ${doc['tujuan'] ?? 'Contoh Tujuan'}'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => _navigateToDetailAndRefresh(context, {
                // Kirim context yang aman
                ...doc,
                'sign_token': doc['sign_token'] ?? 'dummy_token',
                'access_token': doc['access_token'] ?? 'dummy_access',
                'document_id': doc['document_id'] ?? 1,
              }),
            ),
          );
        },
      ),
    );
  }

  // Widget ini sudah benar (menggunakan context dari BlocBuilder)
  void _navigateToDetailAndRefresh(
    BuildContext context, // Context ini berasal dari BlocBuilder (Aman)
    Map<String, dynamic> doc,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfReviewScreen(
          signToken: doc['sign_token'],
          accessToken: doc['access_token'],
          documentId: doc['document_id'].toString(),
        ),
      ),
    );

    if (context.mounted) {
      // context di sini sudah pasti aman
      context.read<VerificationBloc>().add(LoadVerificationDocuments());
    }
  }

  @override
  Widget build(BuildContext context) {
    // PERBAIKAN 2: Bungkus seluruh Scaffold dengan 'Builder'
    // 'context' di sini adalah context ANCESTOR (tidak aman)
    return Builder(
      builder: (BuildContext newContext) {
        // 'newContext' adalah context BARU yang berada DI BAWAH BlocProvider
        // dan sekarang aman untuk digunakan.
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                // BlocBuilder ini sekarang akan menggunakan 'newContext'
                // secara implisit dan berhasil menemukan VerificationBloc
                child: BlocBuilder<VerificationBloc, VerificationState>(
                  builder: (blocContext, state) {
                    // 'blocContext' adalah context yang aman dari BlocBuilder
                    if (state is VerificationLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is VerificationError) {
                      return Center(
                        child: Text(
                          'Terjadi Kesalahan: ${state.message}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (state is VerificationLoaded) {
                      if (state.filteredDocuments.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () async {
                            // Menggunakan blocContext dari BlocBuilder
                            blocContext.read<VerificationBloc>().add(
                              LoadVerificationDocuments(),
                            );
                          },
                          child: ListView(
                            children: const [
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.all(50.0),
                                  child: Text(
                                    'Tidak ada dokumen untuk diverifikasi.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Melewatkan blocContext ke _buildDocumentList
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
