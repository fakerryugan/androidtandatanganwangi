import 'package:android/features/filereview/view/pdf_archive_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/tokenapi.dart';
import '../repository/files_repository.dart';
import '../bloc/files_bloc.dart';

class ArsipDokumenPage extends StatelessWidget {
  const ArsipDokumenPage({super.key});

  String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

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

  void _showCancelConfirmationDialog(
    BuildContext pageContext,
    BuildContext bottomSheetContext,
    Map<String, dynamic> file,
  ) {
    Navigator.of(bottomSheetContext).pop();

    showDialog(
      context: pageContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Batalkan Dokumen?'),
          content: Text(
            'Apakah Anda yakin ingin membatalkan "${file['original_name']}"?\n\n'
            'Jika belum ada yang menyetujui, dokumen akan diarsipkan. '
            'Jika sudah ada, permintaan pembatalan akan dikirim.',
          ),
          actions: [
            TextButton(
              child: const Text('Tutup'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                'Batalkan',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();

                final int? documentId = file['id'] as int?;
                if (documentId != null) {
                  pageContext.read<FilesBloc>().add(
                    CancelDocumentRequested(documentId),
                  );

                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Permintaan pembatalan untuk "${file['original_name']}" dikirim...',
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Gagalan membatalkan: ID Dokumen tidak ditemukan.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
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
    final bool canShare = (status == 'Diverifikasi' || status == 'Disetujui');

    final bool canCancel = (status != 'Diverifikasi' && status != 'Disetujui');

    showModalBottomSheet(
      context: pageContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return _ActionMenuSheet(
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          FilesBloc(repository: FilesRepository(apiService: ApiServiceImpl()))
            ..add(LoadAllFiles()),
      child: BlocListener<FilesBloc, FilesState>(
        listener: (context, state) {
          if (state is FileReadyForSharing) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
          } else if (state is FileCancelSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );

            context.read<FilesBloc>().add(LoadAllFiles());
          } else if (state is FileCancelRequestSent) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.blue,
                ),
              );

            context.read<FilesBloc>().add(LoadAllFiles());
          } else if (state is FileCancelFailure) {
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
                        const Icon(Icons.search, color: Colors.black),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<FilesBloc, FilesState>(
                    buildWhen: (prev, curr) =>
                        prev is! FilesLoaded ||
                        (curr is FilesLoaded &&
                            prev.selectedStatus != curr.selectedStatus),
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
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? const Color.fromARGB(255, 255, 255, 255)
                                      : const Color.fromARGB(255, 0, 0, 0),
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
                              final bool hasQuery =
                                  state.currentQuery.isNotEmpty;
                              final bool hasFilter =
                                  state.selectedStatus != 'Semua';
                              String emptyMessage =
                                  'Anda belum ada dokumen apapun';
                              if (hasQuery || hasFilter) {
                                emptyMessage =
                                    'Tidak ada dokumen yang cocok dengan filter atau pencarian Anda.';
                              }
                              return RefreshIndicator(
                                onRefresh: () async {
                                  context.read<FilesBloc>().add(LoadAllFiles());
                                },
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(50.0),
                                      child: Center(child: Text(emptyMessage)),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return RefreshIndicator(
                              onRefresh: () async {
                                context.read<FilesBloc>().add(LoadAllFiles());
                              },
                              child: ListView.builder(
                                itemCount: state.filteredDocuments.length,
                                itemBuilder: (context, index) {
                                  final file = state.filteredDocuments[index];
                                  final String status =
                                      file['status'] ?? 'Pending';
                                  final String originalName =
                                      file['original_name'] ??
                                      'Nama tidak tersedia';

                                  Widget leadingIcon;
                                  String subtitle;

                                  switch (status) {
                                    case 'Diverifikasi':
                                    case 'Disetujui':
                                      leadingIcon = Image.asset(
                                        'assets/icons/fluent_document-checkmark-20-regular.png',
                                        width: 24,
                                        height: 24,
                                      );
                                      subtitle =
                                          'Status: Selesai\nDiunggah: ${formatDate(file['uploaded_at'])}';
                                      break;

                                    case 'Ditolak':
                                      leadingIcon = Image.asset(
                                        'assets/icons/fluent_document-prohibited-24-regular.png',
                                        width: 24,
                                        height: 24,
                                      );

                                      String comment = '';
                                      final recipients =
                                          file['recipients']
                                              as List<dynamic>? ??
                                          [];

                                      final rejectedRecipient = recipients
                                          .firstWhere((rec) {
                                            if (rec is! Map<String, dynamic>) {
                                              return false;
                                            }
                                            final recStatus =
                                                (rec['status'] as String?)
                                                    ?.toLowerCase() ??
                                                '';
                                            return recStatus == 'rejected' ||
                                                recStatus == 'ditolak';
                                          }, orElse: () => null);

                                      if (rejectedRecipient != null) {
                                        final String? rejectionComment =
                                            rejectedRecipient['keterangan']
                                                as String?;
                                        if (rejectionComment != null &&
                                            rejectionComment.isNotEmpty) {
                                          comment = rejectionComment;
                                        }
                                      }

                                      if (comment.isNotEmpty) {
                                        subtitle =
                                            'Status: Ditolak\nKeterangan: $comment';
                                      } else {
                                        subtitle =
                                            'Status: Ditolak\nDiunggah: ${formatDate(file['uploaded_at'])}';
                                      }
                                      break;

                                    case 'Pending':
                                    default:
                                      leadingIcon = Image.asset(
                                        'assets/icons/fluent_document-sync-24-regular (1).png',
                                        width: 24,
                                        height: 24,
                                      );
                                      subtitle =
                                          'Status: Proses\nDiunggah: ${formatDate(file['uploaded_at'])}';
                                  }

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    child: ListTile(
                                      leading: leadingIcon,
                                      title: Text(
                                        originalName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        subtitle,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      isThreeLine: true,
                                      trailing: IconButton(
                                        icon: const Icon(Icons.more_vert),
                                        onPressed: () {
                                          _showActionMenu(context, file);
                                        },
                                      ),
                                      onTap: () {
                                        _showOptionsDialog(context, file);
                                      },
                                    ),
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
      ),
    );
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
                  fontSize: 22,
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  if (canShare)
                    TextButton(
                      child: const Text(
                        'Bagikan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: onShare,
                    ),
                  TextButton(
                    child: const Text(
                      'Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: onReview,
                  ),
                ],
              ),
            ],
          ),
        ),
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
      case 'Pending':
      default:
        label = 'Proses';
        bgColor = const Color.fromRGBO(19, 29, 93, 1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
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
        width: 24,
        height: 24,
      );
    } else if (isRejected) {
      statusIconWidget = Image.asset(
        'assets/icons/fluent_document-prohibited-24-regular.png',
        width: 24,
        height: 24,
      );
    } else {
      statusIconWidget = Image.asset(
        'assets/icons/fluent_document-sync-24-regular (1).png',
        width: 24,
        height: 24,
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
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 16),
              statusIconWidget,
            ],
          ),
          if (isRejected && comment != null && comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6.0, right: 30.0),
              child: Text(
                'Keterangan : $comment',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionMenuSheet extends StatelessWidget {
  final bool canShare;
  final bool canCancel;
  final VoidCallback onReview;
  final VoidCallback onShare;
  final VoidCallback onCancel;

  const _ActionMenuSheet({
    required this.canShare,
    required this.canCancel,
    required this.onReview,
    required this.onShare,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: <Widget>[
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
          const Divider(height: 1),

          if (canCancel)
            ListTile(
              leading: Icon(Icons.cancel_outlined, color: Colors.red.shade700),
              title: Text(
                'Batalkan Dokumen',
                style: TextStyle(color: Colors.red.shade700),
              ),
              onTap: onCancel,
            ),
        ],
      ),
    );
  }
}
