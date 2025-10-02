part of 'pdfviewer_bloc.dart';

enum PdfStatus { initial, loading, loaded, saving, sending, success, failure }

class PdfViewerState extends Equatable {
  final PdfStatus status;
  final List<Map<String, dynamic>> qrCodes;
  final String currentPdfPath;
  final int documentId;
  final String? errorMessage;
  final String? successMessage; // 1. Tambahkan properti ini

  const PdfViewerState({
    this.status = PdfStatus.initial,
    this.qrCodes = const [],
    this.currentPdfPath = '',
    this.documentId = 0,
    this.errorMessage,
    this.successMessage, // 2. Tambahkan di constructor
  });

  // Helper getter untuk UI
  bool get isProcessing =>
      status == PdfStatus.loading ||
      status == PdfStatus.saving ||
      status == PdfStatus.sending;
  bool get hasUnlockedQr => qrCodes.any((q) => q['locked'] == false);

  PdfViewerState copyWith({
    PdfStatus? status,
    List<Map<String, dynamic>>? qrCodes,
    String? currentPdfPath,
    int? documentId,
    String? errorMessage,
    String? successMessage, // 3. Perbaiki parameter ini (hapus 'required')
    bool clearMessages = false, // Helper untuk membersihkan pesan
  }) {
    return PdfViewerState(
      status: status ?? this.status,
      qrCodes: qrCodes ?? this.qrCodes,
      currentPdfPath: currentPdfPath ?? this.currentPdfPath,
      documentId: documentId ?? this.documentId,
      // Jika clearMessages true, hapus pesan lama
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages
          ? null
          : successMessage ?? this.successMessage, // 4. Gunakan parameter ini
    );
  }

  @override
  List<Object?> get props => [
    status,
    qrCodes,
    currentPdfPath,
    documentId,
    errorMessage,
    successMessage, // 5. Tambahkan di props
  ];
}
