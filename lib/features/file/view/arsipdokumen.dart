import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

// --- SESUAIKAN IMPORT INI DENGAN STRUKTUR FOLDER ANDA ---
import 'package:android/features/filereview/view/pdf_archive_review_screen.dart';
import '../../../core/services/tokenapi.dart';
import '../repository/files_repository.dart';
import '../bloc/files_bloc.dart';

class ArsipDokumenPage extends StatefulWidget {
  const ArsipDokumenPage({super.key});

  @override
  State<ArsipDokumenPage> createState() => _ArsipDokumenPageState();
}

class _ArsipDokumenPageState extends State<ArsipDokumenPage> {
  // Controller untuk search agar teks tidak hilang saat rebuild
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- HELPER FUNCTION: Mencegah UI Rebuild saat Share/Loading ---
  bool _shouldRebuild(FilesState previous, FilesState current) {
    // Jika state adalah proses background (Share/Cancel/Loading Dialog),
    // Jangan rebuild List/Filter agar tampilan tidak blank.
    if (current is FileReadyForSharing ||
        current is FileShareFailure ||
        current is FileCancelProcessing || // Tambahkan ini
        current is FileCancelRequestSent ||
        current is FileCancelSuccess ||
        current is FileCancelFailure) {
      return false; // Pertahankan tampilan sebelumnya
    }
    return true; // Rebuild normal untuk Loading data, Loaded, atau Error Fetch
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  // --- ACTIONS ---

  void _shareFile(BuildContext context, Map<String, dynamic> file) {
    final accessToken = file['access_token'] as String?;
    final encryptedName = file['encrypted_original_filename'] as String?;
    final originalName = file['original_name'] as String?;

    if (accessToken == null || encryptedName == null || originalName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data dokumen tidak lengkap untuk dibagikan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mempersiapkan "$originalName" untuk dibagikan...'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
      ),
    );

    context.read<FilesBloc>().add(
      ShareFile(
        accessToken: accessToken,
        encryptedName: encryptedName,
        originalName: originalName,
      ),
    );
  }

  void _reviewFile(BuildContext context, Map<String, dynamic> file) {
    final accessToken = file['access_token'] as String?;
    final encryptedName = file['encrypted_original_filename'] as String?;
    final originalName = file['original_name'] as String?;

    if (accessToken == null || encryptedName == null || originalName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data dokumen tidak lengkap untuk direview.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: BlocProvider.of<FilesBloc>(context),
          child: PdfArchiveReviewScreen(
            accessToken: accessToken,
            encryptedName: encryptedName,
            originalName: originalName,
          ),
        ),
      ),
    );
  }

  // --- DIALOGS ---

  // --- DIALOG PEMBATALAN DENGAN ALASAN ---
  void _showCancelConfirmationDialog(
    BuildContext pageContext,
    BuildContext bottomSheetContext,
    Map<String, dynamic> file,
  ) {
    Navigator.of(bottomSheetContext).pop(); // Tutup Bottom Sheet

    final String status = file['status'] ?? '';
    final bool isRejected = status == 'Ditolak';

    // Cek apakah sudah ada yang approve?
    final List<dynamic> recipients = file['recipients'] ?? [];
    final bool hasApprovals = recipients.any((r) {
      if (r is Map<String, dynamic>) {
        final s = (r['status'] as String?)?.toLowerCase() ?? '';
        return s == 'approved' || s == 'disetujui';
      }
      return false;
    });

    // Kondisi Wajib Alasan: Jika BUKAN ditolak DAN (sudah ada yang approve)
    final bool requireReason = !isRejected && hasApprovals;

    final String dialogTitle = isRejected
        ? 'Hapus Dokumen?'
        : 'Batalkan Dokumen?';

    String dialogBodyText = isRejected
        ? 'Apakah Anda yakin ingin menghapus permanen "${file['original_name']}"?\n\nDokumen yang ditolak dan dihapus tidak dapat dikembalikan.'
        : 'Apakah Anda yakin ingin membatalkan "${file['original_name']}"?';

    if (!isRejected && hasApprovals) {
      dialogBodyText +=
          '\n\nDokumen ini sudah disetujui oleh beberapa pihak. Anda wajib memberikan alasan pembatalan.';
    } else if (!isRejected) {
      dialogBodyText +=
          '\n\nJika belum ada yang menyetujui, dokumen akan langsung diarsipkan.';
    }

    final String confirmButtonLabel = isRejected ? 'HAPUS' : 'YA, BATALKAN';
    final TextEditingController reasonController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showGeneralDialog(
      context: pageContext,
      barrierDismissible: true,
      barrierLabel: dialogTitle,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: a1.value,
          child: Opacity(opacity: a1.value, child: child),
        );
      },
      pageBuilder: (BuildContext dialogContext, animation, secondaryAnimation) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dialogTitle,
                      style: Theme.of(dialogContext).textTheme.titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isRejected ? Colors.red : Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      dialogBodyText,
                      style: Theme.of(dialogContext).textTheme.bodyMedium,
                    ),

                    // --- INPUT ALASAN (Hanya Muncul Jika Diperlukan) ---
                    if (requireReason) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Alasan Pembatalan',
                          border: OutlineInputBorder(),
                          hintText: 'Contoh: Ada kesalahan pada isi dokumen...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Alasan wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ],

                    // ---------------------------------------------------
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('TUTUP'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            // Validasi form sebelum submit
                            if (requireReason &&
                                !formKey.currentState!.validate()) {
                              return;
                            }

                            Navigator.of(dialogContext).pop();

                            final String? accessToken =
                                file['access_token'] as String?;
                            final String reason = reasonController.text.trim();

                            if (accessToken != null) {
                              pageContext.read<FilesBloc>().add(
                                CancelDocumentRequested(
                                  accessToken,
                                  reason: requireReason ? reason : null,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(pageContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Gagal: Access Token tidak ditemukan",
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: Text(confirmButtonLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOptionsDialog(BuildContext context, Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _DetailDokumenDialog(
          file: file,
          onReview: () {
            Navigator.of(dialogContext).pop();
            _reviewFile(context, file);
          },
          onShare: () {
            Navigator.of(dialogContext).pop();
            _shareFile(context, file);
          },
        );
      },
    );
  }

  void _showActionMenu(BuildContext pageContext, Map<String, dynamic> file) {
    final String status = file['status'] ?? 'Pending';
    // Logic: Kalau verified/approved, bisa share. Kalau cancellation_requested (req batal), gak bisa cancel lagi.
    final bool canShare = (status == 'Diverifikasi' || status == 'Disetujui');
    final bool canCancel =
        (status != 'Diverifikasi' &&
        status != 'Disetujui' &&
        status != 'cancellation_requested');

    showModalBottomSheet(
      context: pageContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return _ActionMenuSheet(
          file: file,
          canShare: canShare,
          canCancel: canCancel,
          onReview: () {
            Navigator.of(bottomSheetContext).pop();
            _reviewFile(pageContext, file);
          },
          onShare: () {
            Navigator.of(bottomSheetContext).pop();
            _shareFile(pageContext, file);
          },
          onCancel: () {
            _showCancelConfirmationDialog(
              pageContext,
              bottomSheetContext,
              file,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, FilesLoaded state) {
    final bool hasQuery = state.currentQuery.isNotEmpty;
    final bool hasFilter = state.selectedStatus != 'Semua';
    String emptyMessage = 'Anda belum ada dokumen apapun';
    if (hasQuery || hasFilter) {
      emptyMessage =
          'Tidak ada dokumen yang cocok dengan filter atau pencarian Anda.';
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<FilesBloc>().add(LoadAllFiles());
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_off_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          FilesBloc(repository: FilesRepository(apiService: ApiServiceImpl()))
            ..add(LoadAllFiles()),
      child: BlocListener<FilesBloc, FilesState>(
        listener: (context, state) {
          // 1. LOADING START
          if (state is FileCancelProcessing) {
            _showStatusDialog(
              context,
              state.fileName, // "Sedang memproses..."
              StatusType.loading,
            );
          }
          // 2. REQUEST TERKIRIM (KASUS SUDAH ADA SIGNER)
          else if (state is FileCancelRequestSent) {
            // Tutup Loading Dialog Dulu
            Navigator.of(context, rootNavigator: true).pop();

            // Tampilkan Info Sukses Mengirim Request
            _showStatusDialog(
              context,
              state.message, // "Permintaan pembatalan dikirim..."
              StatusType.success, // Gunakan icon centang hijau/info
            );
            // Refresh list agar status berubah jadi 'Req Batal'
            context.read<FilesBloc>().add(LoadAllFiles());
          }
          // 3. BERHASIL DIHAPUS LANGSUNG (KASUS BELUM ADA SIGNER)
          else if (state is FileCancelSuccess) {
            Navigator.of(context, rootNavigator: true).pop();
            _showStatusDialog(context, state.message, StatusType.success);
            context.read<FilesBloc>().add(LoadAllFiles());
          }
          // 4. GAGAL
          else if (state is FileCancelFailure) {
            Navigator.of(context, rootNavigator: true).pop();
            _showStatusDialog(context, state.message, StatusType.failure);
          } else if (state is FileReadyForSharing) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            // Trigger Native Share
            Share.shareXFiles([
              XFile(state.tempFilePath),
            ], text: 'Membagikan dokumen: ${state.originalName}');
          } else if (state is FileShareFailure) {
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
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // --- SEARCH BAR ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
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
                            controller: _searchController,
                            onChanged: (query) {
                              context.read<FilesBloc>().add(SearchFiles(query));
                            },
                            decoration: const InputDecoration(
                              hintText: 'Cari dokumen...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                          ),
                        ),
                        // Tombol Clear
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _searchController,
                          builder: (context, value, child) {
                            if (value.text.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(
                                  Icons.search,
                                  color: Colors.black54,
                                ),
                              );
                            }
                            return IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                context.read<FilesBloc>().add(
                                  const SearchFiles(''),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- FILTER CHIPS ---
                  BlocBuilder<FilesBloc, FilesState>(
                    buildWhen: _shouldRebuild,
                    builder: (context, state) {
                      final selectedStatus = (state is FilesLoaded)
                          ? state.selectedStatus
                          : 'Semua';
                      final List<String> filterOptions = [
                        'Semua',
                        'Disetujui',
                        'Pending',
                        'Ditolak',
                      ];

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: filterOptions.map((status) {
                            final isSelected = selectedStatus == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(status),
                                selected: isSelected,
                                onSelected: (isSelected) {
                                  if (isSelected) {
                                    context.read<FilesBloc>().add(
                                      FilterFilesByStatus(status),
                                    );
                                  }
                                },
                                selectedColor: const Color.fromARGB(
                                  255,
                                  93,
                                  123,
                                  244,
                                ),
                                backgroundColor: Colors.white.withOpacity(0.4),
                                side: BorderSide.none,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status Dokumen Anda',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- LIST DOCUMENT ---
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
                      child: BlocBuilder<FilesBloc, FilesState>(
                        buildWhen: _shouldRebuild,
                        builder: (context, state) {
                          if (state is FilesLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (state is FilesError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          if (state is FilesLoaded) {
                            return AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: (state.filteredDocuments.isEmpty)
                                  ? KeyedSubtree(
                                      key: const ValueKey('__empty__'),
                                      child: _buildEmptyState(context, state),
                                    )
                                  : LayoutBuilder(
                                      key: ValueKey(state.selectedStatus),
                                      builder: (context, constraints) {
                                        final bool isWideScreen =
                                            constraints.maxWidth > 600;

                                        if (isWideScreen) {
                                          return RefreshIndicator(
                                            onRefresh: () async {
                                              context.read<FilesBloc>().add(
                                                LoadAllFiles(),
                                              );
                                            },
                                            child: GridView.builder(
                                              padding: const EdgeInsets.all(12),
                                              gridDelegate:
                                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                                    maxCrossAxisExtent: 450.0,
                                                    mainAxisSpacing: 12.0,
                                                    crossAxisSpacing: 12.0,
                                                    childAspectRatio: 3.5,
                                                  ),
                                              itemCount: state
                                                  .filteredDocuments
                                                  .length,
                                              itemBuilder: (context, index) {
                                                return _DocumentCard(
                                                  pageState: this,
                                                  file: state
                                                      .filteredDocuments[index],
                                                );
                                              },
                                            ),
                                          );
                                        } else {
                                          return RefreshIndicator(
                                            onRefresh: () async {
                                              context.read<FilesBloc>().add(
                                                LoadAllFiles(),
                                              );
                                            },
                                            child: ListView.builder(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                                bottom: 20,
                                              ),
                                              itemCount: state
                                                  .filteredDocuments
                                                  .length,
                                              itemBuilder: (context, index) {
                                                return _DocumentCard(
                                                  pageState: this,
                                                  file: state
                                                      .filteredDocuments[index],
                                                );
                                              },
                                            ),
                                          );
                                        }
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
      ),
    );
  }
}

// --- WIDGETS PENDUKUNG ---

class _DocumentCard extends StatelessWidget {
  final _ArsipDokumenPageState pageState;
  final Map<String, dynamic> file;

  const _DocumentCard({required this.pageState, required this.file});

  @override
  Widget build(BuildContext context) {
    final String status = file['status'] ?? 'Pending';
    final String originalName = file['original_name'] ?? 'Nama tidak tersedia';

    Widget leadingIcon;
    String subtitle;

    switch (status) {
      case 'Diverifikasi':
      case 'Disetujui':
        leadingIcon = Image.asset(
          'assets/icons/fluent_document-checkmark-20-regular.png',
          width: 24,
          height: 24,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
        );
        subtitle =
            'Status: Selesai\nDiunggah: ${pageState.formatDate(file['uploaded_at'])}';
        break;

      case 'Ditolak':
        leadingIcon = Image.asset(
          'assets/icons/fluent_document-prohibited-24-regular.png',
          width: 24,
          height: 24,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.cancel, color: Colors.red, size: 24),
        );

        String comment = '';
        final recipients = file['recipients'] as List<dynamic>? ?? [];
        final rejectedRecipient = recipients.firstWhere((rec) {
          if (rec is! Map<String, dynamic>) return false;
          final recStatus = (rec['status'] as String?)?.toLowerCase() ?? '';
          return recStatus == 'rejected' || recStatus == 'ditolak';
        }, orElse: () => null);

        if (rejectedRecipient != null) {
          final String? rejectionComment =
              rejectedRecipient['keterangan'] as String?;
          if (rejectionComment != null && rejectionComment.isNotEmpty) {
            comment = rejectionComment;
          }
        }

        if (comment.isNotEmpty) {
          subtitle = 'Status: Ditolak\nKeterangan: $comment';
        } else {
          subtitle =
              'Status: Ditolak\nDiunggah: ${pageState.formatDate(file['uploaded_at'])}';
        }
        break;

      // --- STATE BARU: REQ BATAL ---
      case 'cancellation_requested':
        leadingIcon = const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 24,
        );
        subtitle = 'Status: Menunggu persetujuan pembatalan dari pihak lain.';
        break;
      // -----------------------------

      case 'Pending':
      default:
        leadingIcon = Image.asset(
          'assets/icons/fluent_document-sync-24-regular (1).png',
          width: 24,
          height: 24,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.sync, color: Colors.blue, size: 24),
        );
        subtitle =
            'Status: Proses\nDiunggah: ${pageState.formatDate(file['uploaded_at'])}';
    }

    return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            leading: leadingIcon,
            title: Text(
              originalName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                pageState._showActionMenu(context, file);
              },
            ),
            onTap: () {
              pageState._showOptionsDialog(context, file);
            },
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0.0, curve: Curves.easeOutCubic);
  }
}

class _DetailDokumenDialog extends StatelessWidget {
  final Map<String, dynamic> file;
  final VoidCallback onReview;
  final VoidCallback onShare;

  const _DetailDokumenDialog({
    required this.file,
    required this.onReview,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final String status = file['status'] ?? 'Pending';
    final String originalName = file['original_name'] ?? 'Detail Dokumen';
    final String tujuanSurat = file['tujuan_surat'] ?? 'Tidak ada tujuan';
    final List<dynamic> recipients = file['recipients'] ?? [];
    final bool canShare = (status == 'Diverifikasi' || status == 'Disetujui');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child:
          ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          originalName,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatusChip(status),
                        const SizedBox(height: 24),
                        Text(
                          'Tujuan Surat : $tujuanSurat',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Ditujukan Kepada :',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          children: recipients.map((rec) {
                            if (rec is Map<String, dynamic>) {
                              return _buildRecipientRow(rec);
                            }
                            return const SizedBox.shrink();
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              child: const Text('Review'),
                              onPressed: onReview,
                            ),
                            if (canShare) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                child: const Text('Bagikan'),
                                onPressed: onShare,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 200.ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeOutCubic,
              ),
    );
  }

  Widget _buildStatusChip(String status) {
    String label;
    Color bgColor;

    switch (status) {
      case 'Diverifikasi':
      case 'Disetujui':
        label = 'Selesai';
        bgColor = Colors.green;
        break;
      case 'Ditolak':
        label = 'Ditolak';
        bgColor = Colors.red;
        break;
      // --- TAMBAHKAN INI DI DIALOG JUGA ---
      case 'cancellation_requested':
        label = 'Req Batal';
        bgColor = Colors.orange;
        break;
      // ------------------------------------
      case 'Pending':
      default:
        label = 'Proses';
        bgColor = const Color.fromRGBO(19, 29, 93, 1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRecipientRow(Map<String, dynamic> recipient) {
    final String status = recipient['status'] ?? 'pending';
    final String name = recipient['nama'] ?? 'N/A';
    final String? comment = recipient['keterangan'] as String?;

    final bool isRejected =
        (status.toLowerCase() == 'ditolak' ||
        status.toLowerCase() == 'rejected');
    final bool isApproved =
        (status.toLowerCase() == 'disetujui' ||
        status.toLowerCase() == 'approved');

    Widget statusIconWidget;
    if (isApproved) {
      statusIconWidget = Image.asset(
        'assets/icons/fluent_document-checkmark-20-regular.png',
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.check_circle, size: 20, color: Colors.green),
      );
    } else if (isRejected) {
      statusIconWidget = Image.asset(
        'assets/icons/fluent_document-prohibited-24-regular.png',
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.cancel, size: 20, color: Colors.red),
      );
    } else {
      statusIconWidget = Image.asset(
        'assets/icons/fluent_document-sync-24-regular (1).png',
        width: 20,
        height: 20,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.sync, size: 20, color: Colors.blue),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Nama : $name',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 16),
              statusIconWidget,
            ],
          ),
          if (isRejected && comment != null && comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Ket: $comment',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionMenuSheet extends StatelessWidget {
  final Map<String, dynamic> file;
  final bool canShare;
  final bool canCancel;
  final VoidCallback onReview;
  final VoidCallback onShare;
  final VoidCallback onCancel;

  const _ActionMenuSheet({
    required this.file,
    required this.canShare,
    required this.canCancel,
    required this.onReview,
    required this.onShare,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRejected = (file['status'] == 'Ditolak');
    final String deleteOrCancelText = isRejected
        ? 'Hapus Dokumen'
        : 'Batalkan Dokumen';

    return SafeArea(
      child:
          Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Opsi Dokumen',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.preview_rounded),
                    title: const Text('Review Dokumen'),
                    onTap: onReview,
                  ),
                  if (canShare)
                    ListTile(
                      leading: const Icon(Icons.share_outlined),
                      title: const Text('Bagikan (Share)'),
                      onTap: onShare,
                    ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  if (canCancel)
                    ListTile(
                      leading: Icon(
                        Icons.cancel_outlined,
                        color: Colors.red.shade700,
                      ),
                      title: Text(
                        deleteOrCancelText,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                      onTap: onCancel,
                    ),
                  const SizedBox(height: 8),
                ],
              )
              .animate()
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.2, end: 0.0, curve: Curves.easeOutCubic),
    );
  }
}

// --- ENUM & HELPER ---

enum StatusType { loading, success, failure }

void _showStatusDialog(BuildContext context, String message, StatusType type) {
  final IconData icon;
  final Color color;
  final bool isDismissible;
  final Duration displayDuration;
  Widget indicator;

  switch (type) {
    case StatusType.loading:
      icon = Icons.loop;
      color = Colors.blue;
      isDismissible = false;
      displayDuration = const Duration(seconds: 60); // Safety timeout
      indicator = const CircularProgressIndicator();
      break;
    case StatusType.success:
      icon = Icons.check_circle;
      color = Colors.green;
      isDismissible = true;
      displayDuration = const Duration(seconds: 2);
      indicator = Icon(icon, color: color, size: 48);
      break;
    case StatusType.failure:
      icon = Icons.error_outline;
      color = Colors.red;
      isDismissible = true;
      displayDuration = const Duration(seconds: 3);
      indicator = Icon(icon, color: color, size: 48);
      break;
  }

  showDialog(
    context: context,
    barrierDismissible: isDismissible,
    builder: (BuildContext dialogContext) {
      if (type != StatusType.loading) {
        Future.delayed(displayDuration, () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        });
      }

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicator,
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    },
  );
}
