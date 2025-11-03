part of 'pdf_archive_review_bloc.dart';

abstract class PdfArchiveReviewState extends Equatable {
  const PdfArchiveReviewState();

  @override
  List<Object> get props => [];
}

class PdfArchiveReviewInitial extends PdfArchiveReviewState {}

class PdfArchiveReviewLoading extends PdfArchiveReviewState {}

/// State ketika PDF berhasil dimuat, membawa path file lokal.
class PdfArchiveReviewLoadSuccess extends PdfArchiveReviewState {
  final String pdfPath;

  const PdfArchiveReviewLoadSuccess({required this.pdfPath});

  @override
  List<Object> get props => [pdfPath];
}

/// State ketika terjadi kegagalan saat memuat PDF.
class PdfArchiveReviewLoadFailure extends PdfArchiveReviewState {
  final String error;

  const PdfArchiveReviewLoadFailure({required this.error});

  @override
  List<Object> get props => [error];
}
