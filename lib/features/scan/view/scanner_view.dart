import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/scanner_bloc.dart';

class ScannerView extends StatelessWidget {
  const ScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(127, 146, 248, 1),
              Color.fromRGBO(175, 219, 248, 1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 87,
                    height: 86,
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SELAMAT DATANG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'APLIKASI DOKUMEN & TANDA TANGAN DIGITAL',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'POLITEKNIK NEGERI BANYUWANGI',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  BlocBuilder<ScannerBloc, ScannerState>(
                    builder: (context, state) {
                      if (state is ScannerLoading || state is ScannerInitial) {
                        return const CircularProgressIndicator(
                          color: Colors.white,
                        );
                      }
                      if (state is ScannerLoadSuccess) {
                        return _BuildSuccessContent(
                          documentData: state.documentData,
                        );
                      }
                      if (state is ScannerLoadFailure) {
                        return _BuildFailureContent(message: state.error);
                      }
                      return const SizedBox.shrink(); // State tidak terduga
                    },
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

class _BuildFailureContent extends StatelessWidget {
  final String message;
  const _BuildFailureContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Text(
        message,
        style: const TextStyle(color: Colors.black),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BuildSuccessContent extends StatelessWidget {
  final Map<String, dynamic> documentData;

  const _BuildSuccessContent({required this.documentData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Judul',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            documentData['original_name'] ?? '-',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const Divider(height: 24),
          const Text(
            'Tanggal Pengajuan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            documentData['uploaded_at'] ?? '-',
            style: const TextStyle(fontSize: 14),
          ),
          const Divider(height: 24),
          const Text(
            'Diajukan Kepada',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ..._buildSignerList(documentData['signers'] ?? []),
          const Divider(height: 24),
          const Text(
            'Status Dokumen',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          _buildStatusBox(
            context,
            documentData['current_status'],
            documentData['download_url'],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox(
    BuildContext context,
    String? status,
    String? downloadUrl,
  ) {
    final isApproved = status == 'approved' || status == 'done';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: isApproved ? Colors.green : Colors.yellow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isApproved ? 'Disetujui' : 'Proses',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isApproved ? Icons.check_circle_outline : Icons.access_time,
                size: 16,
                color: Colors.black,
              ),
            ],
          ),
        ),
        if (isApproved && downloadUrl != null) ...[
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              _launchURL(context, downloadUrl);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Unduh Dokumen', style: TextStyle(fontSize: 14)),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildSignerList(List signers) {
    return signers.map((signer) {
      IconData icon;
      if (signer['status'] == 'approved') {
        icon = Icons.check_circle_outline;
      } else if (signer['status'] == 'rejected') {
        icon = Icons.cancel_outlined;
      } else {
        icon = Icons.access_time;
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              signer['name'] ?? 'Unknown',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 16),
          ],
        ),
      );
    }).toList();
  }

  void _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal membuka link')));
    }
  }
}
