// lib/features/verifikasi/bloc/pdf_review_event.dart
part of 'pdf_review_bloc.dart';

abstract class PdfReviewEvent extends Equatable {
  const PdfReviewEvent();

  @override
  List<Object> get props => [];
}

// Event untuk memulai proses load PDF dari API
class PdfReviewLoadRequested extends PdfReviewEvent {}

// Event untuk mengirimkan aksi (approve/reject)
class PdfReviewSignatureSubmitted extends PdfReviewEvent {
  final String status; // 'approved' or 'rejected'

  const PdfReviewSignatureSubmitted({required this.status});

  @override
  List<Object> get props => [status];
}
