import 'dart:io';
import 'package:android/api/token.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:android/bottom_navbar/bottom_navbar.dart';
import 'package:android/upload_file/generateqr.dart';
import 'pdfviewer_bloc.dart';

extension OffsetClamp on Offset {
  Offset clamp(Offset min, Offset max) {
    return Offset(dx.clamp(min.dx, max.dx), dy.clamp(min.dy, max.dy));
  }
}

class PdfViewerPage extends StatelessWidget {
  final String filePath;
  final int documentId;
  final Map<String, dynamic>? qrData;

  const PdfViewerPage({
    super.key,
    required this.filePath,
    required this.documentId,
    this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PdfViewerBloc(httpClient: http.Client())
        ..add(
          PdfViewerInitialized(
            filePath: filePath,
            documentId: documentId,
            qrData: qrData,
            viewSize: MediaQuery.of(context).size,
          ),
        ),
      child: const PdfViewerView(),
    );
  }
}

class PdfViewerView extends StatefulWidget {
  const PdfViewerView({super.key});

  @override
  State<PdfViewerView> createState() => _PdfViewerViewState();
}

class _PdfViewerViewState extends State<PdfViewerView> {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();
  final PdfViewerController pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final TextEditingController nipController = TextEditingController();
  final TextEditingController tujuanController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const double qrDisplaySize = 100.0;

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: BlocListener<PdfViewerBloc, PdfViewerState>(
        listener: (context, state) {
          if (state.status == PdfStatus.failure) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage}')),
            );
          }
          if (state.status == PdfStatus.success) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(content: Text('Operasi berhasil!')),
            );
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
              (route) => false,
            );
          }
          if (state.status == PdfStatus.saving) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              const SnackBar(content: Text('Menyimpan QR ke PDF...')),
            );
          }
        },
        child: BlocBuilder<PdfViewerBloc, PdfViewerState>(
          builder: (context, state) {
            return Scaffold(
              appBar: _buildAppBar(),
              body: Stack(
                children: [
                  if (state.status != PdfStatus.initial &&
                      state.currentPdfPath.isNotEmpty)
                    _buildPdfViewer(context, state),
                  ..._buildQrOverlays(context, state),
                  _buildBottomNavigation(context, state),
                  if (state.isProcessing)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
              floatingActionButton: _buildFloatingActionButton(context, state),
            );
          },
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

  Widget _buildPdfViewer(BuildContext context, PdfViewerState state) {
    return GestureDetector(
      onTapDown: (details) {
        final unlockedQrIndex = state.qrCodes.indexWhere(
          (q) => q['locked'] != true,
        );
        if (unlockedQrIndex != -1) {
          final pdfViewerSize = _pdfViewerKey.currentContext?.size ?? Size.zero;
          final newPosition = Offset(
            details.localPosition.dx.clamp(
              0.0,
              pdfViewerSize.width - qrDisplaySize,
            ),
            details.localPosition.dy.clamp(
              0.0,
              pdfViewerSize.height - qrDisplaySize,
            ),
          );
          context.read<PdfViewerBloc>().add(
            QrPositionUpdated(
              qrIndex: unlockedQrIndex,
              newPosition: newPosition,
              pageNumber: pdfViewerController.pageNumber,
            ),
          );
        }
      },
      child: SfPdfViewer.file(
        File(state.currentPdfPath),
        key: _pdfViewerKey,
        controller: pdfViewerController,
      ),
    );
  }

  List<Widget> _buildQrOverlays(BuildContext context, PdfViewerState state) {
    return state.qrCodes
        .asMap()
        .entries
        .where((entry) => entry.value['locked'] != true)
        .map((entry) {
          final int index = entry.key;
          final Map<String, dynamic> qr = entry.value;

          return Positioned(
            left: qr['position']?.dx ?? 0,
            top: qr['position']?.dy ?? 0,
            child: GestureDetector(
              onPanUpdate: (details) {
                final pdfViewerSize =
                    _pdfViewerKey.currentContext?.size ?? Size.zero;
                final newPosition = (qr['position'] + details.delta).clamp(
                  Offset.zero,
                  Offset(
                    pdfViewerSize.width - qrDisplaySize,
                    pdfViewerSize.height - qrDisplaySize,
                  ),
                );
                context.read<PdfViewerBloc>().add(
                  QrPositionUpdated(
                    qrIndex: index,
                    newPosition: newPosition,
                    pageNumber: pdfViewerController.pageNumber,
                  ),
                );
              },
              child: Container(
                width: qrDisplaySize,
                height: qrDisplaySize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: QrImageView(
                  data: "${baseUrl}/view/${qr['sign_token']}",
                  size: qrDisplaySize,
                ),
              ),
            ),
          );
        })
        .toList();
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Tombol Back
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_outlined,
                    color: Color(0xFF172B4C),
                  ),
                  onPressed: state.isProcessing
                      ? null
                      : () => _showCancelConfirmationDialog(context),
                ),
              ),
              // Tombol Send
              if (state.qrCodes.isNotEmpty &&
                  state.qrCodes.every((q) => q['locked'] == true))
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: state.status == PdfStatus.sending
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () =>
                              context.read<PdfViewerBloc>().add(DocumentSent()),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(
    BuildContext context,
    PdfViewerState state,
  ) {
    if (state.isProcessing) return null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 70.0),
      child: FloatingActionButton.extended(
        backgroundColor: Colors.white,
        onPressed: () async {
          if (state.hasUnlockedQr) {
            context.read<PdfViewerBloc>().add(
              QrCodesSavedToPdf(pdfViewerKey: _pdfViewerKey),
            );
          } else {
            final result = await showInputDialog(
              context: context,
              formKey: _formKey,
              nipController: nipController,
              tujuanController: tujuanController,
              showTujuan: true,
              totalPages: pdfViewerController.pageCount,
              documentId: state.documentId,
            );
            if (result != null && result['sign_token'] != null) {
              context.read<PdfViewerBloc>().add(
                SignatureAdded(
                  newQrData: {
                    'sign_token': result['sign_token'],
                    'selected_page': result['selected_page'],
                    'position': Offset(
                      MediaQuery.of(context).size.width / 2 - qrDisplaySize / 2,
                      MediaQuery.of(context).size.height / 2 -
                          qrDisplaySize / 2,
                    ),
                    'locked': false,
                  },
                ),
              );
            }
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        label: Text(
          state.hasUnlockedQr ? 'Simpan Semua QR' : '+ Tanda Tangan',
          style: const TextStyle(color: Colors.black),
        ),
        icon: Icon(
          state.hasUnlockedQr ? Icons.save : Icons.edit,
          color: Colors.black,
        ),
      ),
    );
  }

  Future<void> _showCancelConfirmationDialog(BuildContext context) async {
    final bloc = context.read<PdfViewerBloc>(); // Dapatkan BLoC dari context
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Dokumen'),
        content: const Text('Apakah Anda yakin ingin membatalkan dokumen ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(DocumentCancelled());
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}
