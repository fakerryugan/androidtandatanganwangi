import 'package:equatable/equatable.dart';

enum PdfViewerStatus {
  initial,
  loading,
  loaded,
  processing,
  sending,
  success,
  error,
}

class PdfViewerState extends Equatable {
  final PdfViewerStatus status;
  final List<Map<String, dynamic>> qrCodes;
  final String? error;
  final String? filePath;
  final int? documentId;

  const PdfViewerState({
    this.status = PdfViewerStatus.initial,
    this.qrCodes = const [],
    this.error,
    this.filePath,
    this.documentId,
  });

  PdfViewerState copyWith({
    PdfViewerStatus? status,
    List<Map<String, dynamic>>? qrCodes,
    String? error,
    String? filePath,
    int? documentId,
  }) {
    return PdfViewerState(
      status: status ?? this.status,
      qrCodes: qrCodes ?? this.qrCodes,
      error: error,
      filePath: filePath ?? this.filePath,
      documentId: documentId ?? this.documentId,
    );
  }

  @override
  List<Object?> get props => [status, qrCodes, error, filePath, documentId];
}