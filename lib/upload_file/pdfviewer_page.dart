import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:android/upload_file/generateqr.dart';
import 'package:android/upload_file/pdfviewer_bloc.dart';
import 'package:android/upload_file/pdfviewer_event.dart';
import 'package:android/upload_file/pdfviewer_state.dart';
import 'package:android/api/token.dart';

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
  final GlobalKey _pdfWidgetKey = GlobalKey();

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
            _showSnackBar(context, 'Menyimpan QR ke PDF...');
          } else if (state.status == PdfViewerStatus.success) {
            _showSnackBar(context, 'Tanda tangan berhasil disimpan!');
          } else if (state.status == PdfViewerStatus.sending) {
            _showSnackBar(context, 'Dokumen berhasil dikirim!');
            Navigator.of(context).pop();
          } else if (state.status == PdfViewerStatus.error) {
            _showSnackBar(context, 'Error: ${state.error}');
          }
        },
        child: Scaffold(
          appBar: _buildAppBar(),
          body: Stack(
            children: [
              _buildPdfViewer(),
              _buildQrOverlay(),
              _buildLoadingIndicator(),
              _buildBottomNavigation(context),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Edit', style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF172B4C),
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildPdfViewer() {
    return BlocBuilder<PdfViewerBloc, PdfViewerState>(
      builder: (context, state) {
        if (state.filePath == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return SfPdfViewer.file(
          File(state.filePath!),
          key: _pdfWidgetKey,
          controller: _pdfViewerController,
        );
      },
    );
  }

  Widget _buildQrOverlay() {
    return BlocBuilder<PdfViewerBloc, PdfViewerState>(
      buildWhen: (previous, current) => previous.qrCodes != current.qrCodes,
      builder: (context, state) {
        final unlockedQrs = state.qrCodes.where((q) => q['locked'] != true).toList();
        if (unlockedQrs.isEmpty) {
          return const SizedBox.shrink();
        }

        final pdfWidgetRenderBox = _pdfWidgetKey.currentContext?.findRenderObject() as RenderBox?;
        if (pdfWidgetRenderBox == null || state.pageWidth == null || state.pageHeight == null) {
          return const SizedBox.shrink();
        }
        
        // Dapatkan properti dari controller
        final zoomLevel = _pdfViewerController.zoomLevel;
        final scrollOffset = _pdfViewerController.scrollOffset;
        final viewPortSize = pdfWidgetRenderBox.size;

        return Stack(
          children: unlockedQrs.map((qr) {
            final index = state.qrCodes.indexOf(qr);
            final currentRelativePosition = qr['position'] as Offset;

            // Konversi posisi relatif dari PDF ke posisi di layar
            // Ini adalah rumus yang benar
            final screenX = (currentRelativePosition.dx * state.pageWidth! * zoomLevel) - scrollOffset.dx;
            final screenY = (currentRelativePosition.dy * state.pageHeight! * zoomLevel) - scrollOffset.dy;

            return Positioned(
              left: screenX,
              top: screenY,
              child: Draggable(
                feedback: SizedBox(
                  width: PdfViewerPage.qrDisplaySize,
                  height: PdfViewerPage.qrDisplaySize,
                  child: QrImageView(data: "${baseUrl}/view/${qr['sign_token']}"),
                ),
                child: SizedBox(
                  width: PdfViewerPage.qrDisplaySize,
                  height: PdfViewerPage.qrDisplaySize,
                  child: QrImageView(data: "${baseUrl}/view/${qr['sign_token']}"),
                ),
                onDragEnd: (details) {
                  final dropPosition = details.offset;
                  final localOffset = pdfWidgetRenderBox.globalToLocal(dropPosition);

                  // Konversi posisi lokal ke posisi relatif terhadap halaman PDF
                  final relativeX = (localOffset.dx + scrollOffset.dx) / (state.pageWidth! * zoomLevel);
                  final relativeY = (localOffset.dy + scrollOffset.dy) / (state.pageHeight! * zoomLevel);
                  
                  context.read<PdfViewerBloc>().add(UpdateQrPosition(index, Offset(relativeX, relativeY)));
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return BlocBuilder<PdfViewerBloc, PdfViewerState>(
      builder: (context, state) {
        if (state.status == PdfViewerStatus.processing || state.status == PdfViewerStatus.sending) {
          return const Center(child: CircularProgressIndicator());
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
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
                _buildBackButton(context),
                _buildSendButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
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

  Widget _buildSendButton(BuildContext context) {
    return BlocBuilder<PdfViewerBloc, PdfViewerState>(
      builder: (context, state) {
        final canSend = state.qrCodes.any((q) => q['locked']);
        if (!state.qrCodes.isNotEmpty) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: canSend ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(15),
          ),
          child: state.status == PdfViewerStatus.sending
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: canSend ? () {
                    if (state.filePath != null && state.documentId != null) {
                      context.read<PdfViewerBloc>().add(SendDocument(state.filePath!, state.documentId!));
                    }
                  } : null,
                ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return BlocBuilder<PdfViewerBloc, PdfViewerState>(
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
                    totalPages: _pdfViewerController.pageCount,
                    documentId: widget.documentId,
                  );

                  if (result != null && result['sign_token'] != null) {
                    final currentPage = _pdfViewerController.pageNumber;
                    context.read<PdfViewerBloc>().add(AddQrCode({
                      ...result,
                      'selected_page': currentPage,
                    }));
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
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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