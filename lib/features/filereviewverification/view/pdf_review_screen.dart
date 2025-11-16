import 'package:android/features/filereviewverification/bloc/pdf_review_bloc.dart';
import 'package:android/features/filereviewverification/respository/pdf_review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfReviewScreen extends StatefulWidget {
  final String signToken;
  final String documentId;
  final String accessToken;

  const PdfReviewScreen({
    super.key,
    required this.signToken,
    required this.documentId,
    required this.accessToken,
  });

  @override
  State<PdfReviewScreen> createState() => _PdfReviewScreenState();
}

class _PdfReviewScreenState extends State<PdfReviewScreen> {
  int? _totalPages;
  int? _currentPage;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => PdfReviewRepository(),
      child: BlocProvider(
        create: (context) => PdfReviewBloc(
          repository: context.read<PdfReviewRepository>(),
          accessToken: widget.accessToken,
          documentId: widget.documentId,
          signToken: widget.signToken,
        )..add(PdfReviewLoadRequested()),
        child: Scaffold(
          appBar: _buildAppBar(),
          body: _buildBody(),
          bottomNavigationBar: _buildBottomAppBar(),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Review Dokumen',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF172B4C),
      centerTitle: true,

      automaticallyImplyLeading: false,
    );
  }

  Widget _buildBody() {
    return BlocConsumer<PdfReviewBloc, PdfReviewState>(
      listener: (context, state) {
        if (state is PdfReviewActionSuccess) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );

          Navigator.pop(context, true);
        }

        if (state is PdfReviewActionFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
        }
      },
      builder: (context, state) {
        if (state is PdfReviewLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is PdfReviewLoadFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.error),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.read<PdfReviewBloc>().add(
                    PdfReviewLoadRequested(),
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }
        if (state is PdfReviewLoadSuccess) {
          return Stack(
            children: [
              PDFView(
                filePath: state.pdfPath,
                onRender: (pages) => setState(() => _totalPages = pages),
                onPageChanged: (page, total) => setState(() {
                  _currentPage = (page ?? 0) + 1;
                  _totalPages = total;
                }),
              ),
              if (_currentPage != null && _totalPages != null)
                _buildPageCounter(),

              if (state.isSigning)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),

                        Text(
                          'Memproses...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }
        return const Center(child: Text('State tidak diketahui'));
      },
    );
  }

  Widget _buildPageCounter() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Halaman $_currentPage/$_totalPages',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return Builder(
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomAppBar(
            color: const Color(0xFF172B4C),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    Icons.arrow_back_outlined,
                    Colors.grey.shade300,
                    () => Navigator.pop(context),
                  ),

                  _buildActionButton(
                    Icons.close,
                    Colors.red,
                    () => _showRejectDialog(context),
                  ),

                  _buildActionButton(
                    Icons.verified,
                    Colors.green,
                    () => _confirmApprove(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  void _showRejectDialog(BuildContext blocContext) {
    String comment = '';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak Dokumen'),
        content: TextField(
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Alasan penolakan'),
          onChanged: (value) => comment = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (comment.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Komentar wajib diisi saat menolak'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              blocContext.read<PdfReviewBloc>().add(
                PdfReviewSignatureSubmitted(
                  status: 'rejected',
                  comment: comment,
                ),
              );
            },
            child: const Text('Kirim', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmApprove(BuildContext blocContext) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Setujui Dokumen'),
        content: const Text('Anda yakin ingin menyetujui dokumen ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              blocContext.read<PdfReviewBloc>().add(
                const PdfReviewSignatureSubmitted(status: 'approved'),
              );
            },
            child: const Text('Setujui', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
