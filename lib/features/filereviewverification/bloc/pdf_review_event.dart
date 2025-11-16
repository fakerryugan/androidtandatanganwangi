// lib/features/filereviewverification/bloc/pdf_review_event.dart
part of 'pdf_review_bloc.dart';

abstract class PdfReviewEvent extends Equatable {
  const PdfReviewEvent();

  @override
  List<Object> get props => [];
}

class PdfReviewLoadRequested extends PdfReviewEvent {}

class PdfReviewSignatureSubmitted extends PdfReviewEvent {
  final String status; // approved / rejected
  final String? comment; // komentar opsional (wajib saat rejected)

  const PdfReviewSignatureSubmitted({required this.status, this.comment});

  @override
  List<Object> get props => [status, comment ?? ''];
}
