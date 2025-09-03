import 'dart:io';
import 'package:android/api/token.dart';
import 'package:android/bottom_navbar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:android/upload_file/generateqr.dart';
import 'package:android/upload_file/pdfviewer_bloc.dart';
import 'package:android/upload_file/pdfviewer_event.dart';
import 'package:android/upload_file/pdfviewer_state.dart';
import 'package:android/utils/offset_extensions.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final int documentId;
  final Map<String, dynamic>? qrData;

  static const double qrDisplaySize = 100.0;

  const PdfViewerPage({
    Key? key,
    required this.filePath,
    required this.documentId,
    this.qrData,
  }) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  void initState() {
    _pdfViewerController = PdfViewerController();
    super.initState();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  // Metode untuk mengkonversi koordinat layar ke koordinat PDF
  Offset _getPDFCoordinates(Offset localPosition) {
    final zoomLevel = _pdfViewerController.zoomLevel;
    final scrollOffset = _pdfViewerController.scrollOffset;
    
    // Hitung posisi relatif terhadap halaman PDF.
    final x = (localPosition.dx + scrollOffset.dx) / zoomLevel;
    final y = (localPosition.dy + scrollOffset.dy) / zoomLevel;

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PdfViewerBloc()
        ..add(LoadPdfViewer(
          filePath: widget.filePath,
          documentId: widget.documentId,
          qrData: widget.qrData,
        )),
      child: BlocListener<PdfViewerBloc, PdfViewerState>(
        listener: (context, state) {
          if (state.status == PdfViewerStatus.processing) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(content: Text('Menyimpan QR ke PDF...')),
            );
          } else if (state.status == PdfViewerStatus.success) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(content: Text('Tanda tangan berhasil disimpan!')),
            );
          } else if (state.status == PdfViewerStatus.sending) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(content: Text('Dokumen berhasil dikirim!')),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
              (route) => false,
            );
          } else if (state.status == PdfViewerStatus.error) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text('Error: ${state.error}')),
            );
          }
        },
        child: Scaffold(
          appBar: _buildAppBar(context),
          body: Stack(
            children: [
              // BLOC BUILDER HANYA UNTUK PDF VIEWER
              BlocBuilder<PdfViewerBloc, PdfViewerState>(
                builder: (context, state) {
                  if (state.filePath == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return SfPdfViewer.file(
                    File(state.filePath!),
                    key: _pdfViewerKey,
                    controller: _pdfViewerController,
                  );
                },
              ),
              
              // GestureDetector untuk mendeteksi posisi QR
              BlocBuilder<PdfViewerBloc, PdfViewerState>(
                buildWhen: (previous, current) => previous.qrCodes != current.qrCodes,
                builder: (context, state) {
                  final unlockedQrsExist = state.qrCodes.any((q) => !q['locked']);

                  return GestureDetector(
                    onTapUp: (details) {
                      if (unlockedQrsExist) {
                        final bloc = context.read<PdfViewerBloc>();
                        final pdfCoordinates = _getPDFCoordinates(details.localPosition);
                        bloc.add(UpdateQrPosition(state.qrCodes.indexWhere((q) => !q['locked']), pdfCoordinates));
                      }
                    },
                    child: Container(
                      // Container transparan agar gestur bekerja di atas PDF
                      color: Colors.transparent,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  );
                },
              ),

              // BLOC BUILDER HANYA UNTUK OVERLAY QR CODE
              BlocBuilder<PdfViewerBloc, PdfViewerState>(
                buildWhen: (previous, current) => previous.qrCodes != current.qrCodes,
                builder: (context, state) {
                  final unlockedQrs = state.qrCodes.where((q) => q['locked'] != true).toList();
                  if (unlockedQrs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final zoomLevel = _pdfViewerController.zoomLevel;
                  final scrollOffset = _pdfViewerController.scrollOffset;

                  return Stack(
                    children: unlockedQrs.map((qr) {
                      final index = state.qrCodes.indexOf(qr);
                      final screenX = (qr['position']?.dx ?? 0) * zoomLevel - scrollOffset.dx;
                      final screenY = (qr['position']?.dy ?? 0) * zoomLevel - scrollOffset.dy;
                      
                      return Positioned(
                        left: screenX,
                        top: screenY,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            final bloc = context.read<PdfViewerBloc>();
                            final deltaPdfX = details.delta.dx / zoomLevel;
                            final deltaPdfY = details.delta.dy / zoomLevel;

                            final currentPdfX = qr['position']?.dx ?? 0;
                            final currentPdfY = qr['position']?.dy ?? 0;

                            final newPdfPosition = Offset(
                              currentPdfX + deltaPdfX,
                              currentPdfY + deltaPdfY,
                            );
                            bloc.add(UpdateQrPosition(index, newPdfPosition));
                          },
                          child: Container(
                            width: PdfViewerPage.qrDisplaySize,
                            height: PdfViewerPage.qrDisplaySize,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red, width: 2),
                            ),
                            child: QrImageView(
                              data: "${baseUrl}/view/${qr['sign_token']}",
                              size: PdfViewerPage.qrDisplaySize,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              
              // Widget lainnya
              BlocBuilder<PdfViewerBloc, PdfViewerState>(
                builder: (context, state) {
                  return _buildBottomNavigation(context, state);
                },
              ),
              BlocBuilder<PdfViewerBloc, PdfViewerState>(
                builder: (context, state) {
                  if (state.status == PdfViewerStatus.processing || state.status == PdfViewerStatus.sending) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          floatingActionButton: BlocBuilder<PdfViewerBloc, PdfViewerState>(
            builder: (context, state) {
              final unlockedQrsExist = state.qrCodes.any((q) => !q['locked']);
              return Visibility(
                visible: state.status != PdfViewerStatus.processing && state.status != PdfViewerStatus.sending && state.filePath != null,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 70.0),
                  child: FloatingActionButton.extended(
                    backgroundColor: Colors.white,
                    onPressed: () async {
                      if (unlockedQrsExist) {
                        context.read<PdfViewerBloc>().add(SaveAllQrCodesToPdf());
                      } else {
                        final result = await showInputDialog(
                          context: context,
                          formKey: GlobalKey<FormState>(),
                          nipController: TextEditingController(),
                          tujuanController: TextEditingController(),
                          showTujuan: true,
                          totalPages: 10,
                          documentId: widget.documentId,
                        );

                        if (result != null && result['sign_token'] != null) {
                          context.read<PdfViewerBloc>().add(AddQrCode(result));
                        }
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                    label: Text(
                      unlockedQrsExist ? 'Simpan & Kunci' : '+ Tanda Tangan',
                      style: const TextStyle(color: Colors.black),
                    ),
                    icon: Icon(
                      unlockedQrsExist ? Icons.save : Icons.edit,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Edit', style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF172B4C),
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildBottomNavigation(BuildContext context, PdfViewerState state) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: Container(
          height: 60,
          color: const Color(0xFF172B4C),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBackButton(context, state),
                if (state.qrCodes.isNotEmpty) // Tampilkan tombol Kirim jika ada setidaknya satu QR
                  _buildSendButton(context, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, PdfViewerState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_outlined, color: Color(0xFF172B4C)),
        onPressed: () => _showCancelConfirmationDialog(context),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context, PdfViewerState state) {
    return Container(
      decoration: BoxDecoration(
        color: state.qrCodes.any((q) => q['locked']) ? Colors.green : Colors.grey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: state.status == PdfViewerStatus.sending
          ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white),
            )
          : IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: state.qrCodes.any((q) => q['locked']) ? () {
                if (state.filePath != null && state.documentId != null) {
                  context.read<PdfViewerBloc>().add(SendDocument(state.filePath!, state.documentId!));
                }
              } : null,
            ),
    );
  }

  Future<void> _showCancelConfirmationDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Dokumen'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan dokumen ini? Semua data akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<PdfViewerBloc>().add(CancelDocument(widget.documentId));
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}