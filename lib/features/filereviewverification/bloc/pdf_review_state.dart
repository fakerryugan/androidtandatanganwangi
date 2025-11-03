// lib/features/verifikasi/bloc/pdf_review_state.dart
part of 'pdf_review_bloc.dart';

abstract class PdfReviewState extends Equatable {
  const PdfReviewState();

  @override
  List<Object> get props => [];
}

class PdfReviewInitial extends PdfReviewState {}

class PdfReviewLoading extends PdfReviewState {}

// State ketika PDF berhasil dimuat dan siap ditampilkan
class PdfReviewLoadSuccess extends PdfReviewState {
  final String pdfPath;
  final bool
  isSigning; // Untuk menampilkan loading indicator saat proses approve/reject

  const PdfReviewLoadSuccess({required this.pdfPath, this.isSigning = false});

  PdfReviewLoadSuccess copyWith({String? pdfPath, bool? isSigning}) {
    return PdfReviewLoadSuccess(
      pdfPath: pdfPath ?? this.pdfPath,
      isSigning: isSigning ?? this.isSigning,
    );
  }

  @override
  List<Object> get props => [pdfPath, isSigning];
}

// State ketika gagal memuat PDF
class PdfReviewLoadFailure extends PdfReviewState {
  final String error;

  const PdfReviewLoadFailure({required this.error});

  @override
  List<Object> get props => [error];
}

// State sementara untuk menandakan aksi approve/reject berhasil (untuk listener)
class PdfReviewActionSuccess extends PdfReviewState {
  final String message;
  const PdfReviewActionSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

// State sementara untuk menandakan aksi approve/reject gagal (untuk listener)
class PdfReviewActionFailure extends PdfReviewState {
  final String error;
  const PdfReviewActionFailure({required this.error});

  @override
  List<Object> get props => [error];
}
