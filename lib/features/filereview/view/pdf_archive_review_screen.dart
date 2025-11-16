import 'dart:io';
import 'package:android/features/file/bloc/files_bloc.dart';
import 'package:android/features/filereview/reponsitory/pdf_archive_review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import '../bloc/pdf_archive_review_bloc.dart';

class PdfArchiveReviewScreen extends StatelessWidget {
  final String accessToken;
  final String encryptedName;
  final String originalName;

  const PdfArchiveReviewScreen({
    super.key,
    required this.accessToken,
    required this.encryptedName,
    required this.originalName,
  });

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => PdfArchiveReviewRepository(),
      child: BlocProvider(
        create: (context) => PdfArchiveReviewBloc(
          repository: context.read<PdfArchiveReviewRepository>(),
          accessToken: accessToken,
          encryptedName: encryptedName,
        )..add(PdfArchiveReviewLoadRequested()),
        child: BlocListener<FilesBloc, FilesState>(
          listener: (context, state) {
            if (state is FileReadyForSharing) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              // Panggil dialog share
              Share.shareXFiles([
                XFile(state.tempFilePath),
              ], text: 'Membagikan dokumen: ${state.originalName}');
            } else if (state is FileShareFailure) {
              // Tampilkan error jika share gagal
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
          // --- AKHIR TAMBAHAN ---
          child: Scaffold(appBar: _buildAppBar(context), body: _buildBody()),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        originalName,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: const Color.fromRGBO(127, 146, 248, 1),
      elevation: 1,
      actions: [
        // --- PERUBAHAN: Ikon dan fungsi diubah ke Share ---
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white), // Ikon diubah
          tooltip: 'Bagikan File', // Tooltip diubah
          onPressed: () => _startShare(context), // Fungsi diubah
        ),
        // --- AKHIR PERUBAHAN ---
      ],
    );
  }

  // --- PERUBAHAN: Nama fungsi dan logikanya diubah ---
  void _startShare(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Mempersiapkan "$originalName" untuk dibagikan...'),
          backgroundColor: Colors.blue,
        ),
      );

    // Kirim event ShareFile (dari implementasi kita sebelumnya)
    context.read<FilesBloc>().add(
      ShareFile(
        accessToken: accessToken,
        encryptedName: encryptedName,
        originalName: originalName,
      ),
    );
  }
  // --- AKHIR PERUBAHAN ---

  Widget _buildBody() {
    return BlocBuilder<PdfArchiveReviewBloc, PdfArchiveReviewState>(
      builder: (context, state) {
        if (state is PdfArchiveReviewLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is PdfArchiveReviewLoadFailure) {
          return _buildErrorWidget(context, state.error);
        }
        if (state is PdfArchiveReviewLoadSuccess) {
          return SfPdfViewer.file(File(state.pdfPath));
        }
        return const Center(child: Text('Silakan muat dokumen.'));
      },
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Dokumen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('Detail: $error', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<PdfArchiveReviewBloc>().add(
                PdfArchiveReviewLoadRequested(),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
