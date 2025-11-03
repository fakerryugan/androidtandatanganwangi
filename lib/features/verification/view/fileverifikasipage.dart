import 'package:android/core/services/tokenapi.dart';
import 'package:android/features/filereviewverification/view/pdf_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/verification_repository.dart';
import '../bloc/verification_bloc.dart';

class FileVerifikasiPage extends StatelessWidget {
  const FileVerifikasiPage({super.key});

  // --- WIDGET BUILDERS ---

  Widget _buildHeader(BuildContext context) {
    return Container(
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

              child: Image.asset('assets/images/pp.png', fit: BoxFit.cover),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: TextField(
              onChanged: (query) {
                context.read<VerificationBloc>().add(
                  SearchVerificationDocuments(query),
                );
              },

              decoration: const InputDecoration(
                hintText: 'Cari file...',

                border: InputBorder.none,
              ),
            ),
          ),

          const Icon(Icons.search, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),

      child: Row(
        children: [
          Text(
            'Dokumen Perlu Verifikasi',

            style: TextStyle(
              fontSize: 18,

              fontWeight: FontWeight.bold,

              color: Colors.white,
            ),
          ),
        ],
      ),
    );
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
        itemCount: documents.length,

        itemBuilder: (context, index) {
          final doc = documents[index];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

            child: ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),

              title: Text(doc['original_name'] ?? 'Dokumen Tanpa Nama'),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text('Tanggal: ${doc['uploaded_at'] ?? '-'}'),

                  Text('Tujuan: ${doc['tujuan'] ?? '-'}'),
                ],
              ),

              trailing: const Icon(Icons.arrow_forward),

              onTap: () => _navigateToDetailAndRefresh(context, doc),
            ),
          );
        },
      ),
    );
  }

  // --- LOGIC NAVIGASI DAN REFRESH ---

  void _navigateToDetailAndRefresh(
    BuildContext context,

    Map<String, dynamic> doc,
  ) async {
    // Navigasi ke halaman detail dan tunggu hasilnya (await)

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

    // Setelah kembali dari halaman detail, kirim event untuk memuat ulang data

    // Pastikan context masih valid sebelum digunakan

    if (context.mounted) {
      context.read<VerificationBloc>().add(LoadVerificationDocuments());
    }
  }

  // --- BUILD METHOD UTAMA ---

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // BENAR ✅
      create: (context) => VerificationBloc(
        repository: VerificationRepository(apiService: ApiServiceImpl()),
      )..add(LoadVerificationDocuments()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(127, 146, 248, 1),

                    Color.fromRGBO(175, 219, 248, 1),
                  ],

                  begin: Alignment.topLeft,

                  end: Alignment.bottomRight,
                ),
              ),

              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    _buildHeader(context),

                    const SizedBox(height: 12),

                    _buildSectionTitle(),

                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,

                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),

                            topRight: Radius.circular(20),
                          ),
                        ),

                        child: BlocBuilder<VerificationBloc, VerificationState>(
                          builder: (context, state) {
                            if (state is VerificationLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (state is VerificationError) {
                              return Center(
                                child: Text(
                                  'Terjadi Kesalahan: ${state.message}',
                                ),
                              );
                            }

                            if (state is VerificationLoaded) {
                              if (state.filteredDocuments.isEmpty) {
                                return RefreshIndicator(
                                  onRefresh: () async {
                                    context.read<VerificationBloc>().add(
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
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return _buildDocumentList(
                                context,

                                state.filteredDocuments,
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
          );
        },
      ),
    );
  }
}
