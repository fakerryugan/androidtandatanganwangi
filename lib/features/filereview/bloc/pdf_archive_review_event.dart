part of 'pdf_archive_review_bloc.dart';

abstract class PdfArchiveReviewEvent extends Equatable {
  const PdfArchiveReviewEvent();

  @override
  List<Object> get props => [];
}

/// Event yang dipicu untuk meminta BLoC memuat PDF.
class PdfArchiveReviewLoadRequested extends PdfArchiveReviewEvent {}
