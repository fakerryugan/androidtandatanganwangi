import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VerificationDetailDialog extends StatelessWidget {
  final Map<String, dynamic> file;
  final VoidCallback onReview;

  const VerificationDetailDialog({
    super.key,
    required this.file,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: Gunakan .toString() untuk memastikan data yang masuk dipaksa jadi String
    // Ini mencegah error jika API mengirim angka (int) bukannya text
    final String status = (file['status'] ?? 'Pending').toString();
    final String originalName = (file['original_name'] ?? 'Detail Dokumen')
        .toString();

    final String tujuanSurat =
        (file['tujuan_surat'] ?? file['tujuan'] ?? file['perihal'] ?? '-')
            .toString();

    // FIX: Casting aman untuk List recipients
    final List<dynamic> recipients = (file['recipients'] is List)
        ? file['recipients']
        : [];

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
                        // Judul Dokumen
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

                        // Chip Status Dokumen Utama
                        _buildStatusChip(status),

                        const SizedBox(height: 24),

                        // Tujuan Surat
                        Text(
                          'Tujuan Surat : $tujuanSurat',
                          style: const TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Header Daftar Penanda Tangan
                        const Text(
                          'Daftar Penanda Tangan :',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // List Penanda Tangan (Recipients)
                        if (recipients.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "- Belum ada data penanda tangan -",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        else
                          Column(
                            children: recipients.map((rec) {
                              // Cek apakah item benar-benar Map sebelum dirender
                              if (rec is Map<String, dynamic>) {
                                return _buildRecipientRow(rec);
                              } else if (rec is Map) {
                                // Handle jika terdeteksi sebagai Map<dynamic, dynamic>
                                return _buildRecipientRow(
                                  Map<String, dynamic>.from(rec),
                                );
                              }
                              return const SizedBox.shrink();
                            }).toList(),
                          ),

                        const SizedBox(height: 24),

                        // Tombol Aksi (Kembali & Review)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Tombol Kembali
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                              ),
                              child: const Text('Kembali'),
                            ),
                            const SizedBox(width: 8),

                            // Tombol Review
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                // Pastikan onReview dijalankan
                                onReview();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Review'),
                            ),
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

  // Helper: Chip Status Utama
  Widget _buildStatusChip(String status) {
    String label;
    Color bgColor;

    // Normalisasi status ke lowercase untuk perbandingan yang lebih aman
    final s = status.toLowerCase();

    if (s == 'diverifikasi' || s == 'disetujui' || s == 'approved') {
      label = 'Selesai';
      bgColor = Colors.green;
    } else if (s == 'ditolak' || s == 'rejected') {
      label = 'Ditolak';
      bgColor = Colors.red;
    } else {
      label = 'Proses'; // Default untuk Pending atau lainnya
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

  // Helper: Baris untuk setiap Penanda Tangan
  Widget _buildRecipientRow(Map<String, dynamic> recipient) {
    // FIX: Gunakan toString() agar aman jika API mengirim null atau int
    final String status = (recipient['status'] ?? 'pending').toString();
    final String name = (recipient['nama'] ?? 'N/A').toString();

    // FIX: Jangan gunakan 'as String?', gunakan null check manual
    final String? comment = recipient['keterangan']?.toString();

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
        errorBuilder: (ctx, _, __) =>
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
      );
    } else if (isRejected) {
      statusIconWidget = Image.asset(
        'assets/icons/fluent_document-prohibited-24-regular.png',
        width: 20,
        height: 20,
        errorBuilder: (ctx, _, __) =>
            const Icon(Icons.cancel, color: Colors.red, size: 20),
      );
    } else {
      statusIconWidget = Image.asset(
        'assets/icons/fluent_document-sync-24-regular (1).png',
        width: 20,
        height: 20,
        errorBuilder: (ctx, _, __) =>
            const Icon(Icons.sync, color: Colors.blue, size: 20),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              statusIconWidget,
            ],
          ),
          // Jika Ditolak, tampilkan alasan
          if (isRejected &&
              comment != null &&
              comment.isNotEmpty &&
              comment != 'null')
            Padding(
              padding: const EdgeInsets.only(top: 4.0, right: 24.0),
              child: Text(
                'Ket: $comment',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const Divider(height: 12, thickness: 0.5),
        ],
      ),
    );
  }
}
