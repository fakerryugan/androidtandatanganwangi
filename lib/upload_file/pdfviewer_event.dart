part of 'pdfviewer_bloc.dart';

abstract class PdfViewerEvent extends Equatable {
  const PdfViewerEvent();

  @override
  List<Object?> get props => [];
}

class PdfViewerInitialized extends PdfViewerEvent {
  final String filePath;
  final int documentId;
  final Map<String, dynamic>? qrData;
  final Size viewSize;

  const PdfViewerInitialized({
    required this.filePath,
    required this.documentId,
    required this.viewSize,
    this.qrData,
  });

  @override
  List<Object?> get props => [filePath, documentId, qrData, viewSize];
}

// Event saat pengguna menambahkan tanda tangan baru
class SignatureAdded extends PdfViewerEvent {
  final Map<String, dynamic> newQrData;

  const SignatureAdded({required this.newQrData});

  @override
  List<Object?> get props => [newQrData];
}

// Event saat posisi QR code diubah (drag atau tap)
class QrPositionUpdated extends PdfViewerEvent {
  final int qrIndex;
  final Offset newPosition;
  final int pageNumber;

  const QrPositionUpdated({
    required this.qrIndex,
    required this.newPosition,
    required this.pageNumber,
  });

  @override
  List<Object?> get props => [qrIndex, newPosition, pageNumber];
}

// Event saat pengguna menekan tombol simpan QR ke PDF
class QrCodesSavedToPdf extends PdfViewerEvent {
  final GlobalKey<SfPdfViewerState> pdfViewerKey;

  const QrCodesSavedToPdf({required this.pdfViewerKey});

  @override
  List<Object?> get props => [pdfViewerKey];
}

// Event saat pengguna menekan tombol kirim dokumen
class DocumentSent extends PdfViewerEvent {}

// Event saat pengguna membatalkan dokumen
class DocumentCancelled extends PdfViewerEvent {}
