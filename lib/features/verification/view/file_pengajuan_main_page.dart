import 'package:android/core/services/tokenapi.dart';
import 'package:android/features/verification/bloc/rejection_bloc.dart'; // Import BLoC baru
import 'package:android/features/verification/bloc/verification_bloc.dart';
import 'package:android/features/verification/repository/verification_repository.dart';
import 'package:android/features/verification/view/file_pengajuan_penolakan.dart';
import 'package:android/features/verification/view/fileverifikasipage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FileReviewMainPage extends StatelessWidget {
  const FileReviewMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Jumlah tab
      child: Scaffold(
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Status Dokumen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    // PERBAIKAN: Sediakan Repository di sini
                    child: RepositoryProvider(
                      create: (context) =>
                          VerificationRepository(apiService: ApiServiceImpl()),
                      child: TabBarView(
                        children: [
                          // Tab 1: Verifikasi (Menggunakan Repository dari context)
                          BlocProvider(
                            create: (context) => VerificationBloc(
                              // Ambil repo dari RepositoryProvider di atas
                              repository: context
                                  .read<VerificationRepository>(),
                            )..add(LoadVerificationDocuments()),
                            child: const FileVerifikasiPage(),
                          ),

                          // Tab 2: Penolakan (Menggunakan BLoC baru)
                          BlocProvider(
                            create: (context) => RejectionBloc(
                              // Ambil repo yang sama
                              repository: context
                                  .read<VerificationRepository>(),
                            )..add(LoadRejectionDocuments()),
                            child: const FilePenolakanPage(),
                          ),
                        ],
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withOpacity(0.3),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Verifikasi Dokumen'),
          Tab(text: 'Pengajuan Penolakan'),
        ],
      ),
    );
  }
}
