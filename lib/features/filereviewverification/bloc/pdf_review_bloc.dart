// lib/features/filereviewverification/bloc/pdf_review_bloc.dart

import 'package:android/features/filereviewverification/respository/pdf_review_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'pdf_review_event.dart';
part 'pdf_review_state.dart';

class PdfReviewBloc extends Bloc<PdfReviewEvent, PdfReviewState> {
  final PdfReviewRepository _repository;
  final String accessToken;
  final String documentId;
  final String signToken;

  PdfReviewBloc({
    required PdfReviewRepository repository,
    required this.accessToken,
    required this.documentId,
    required this.signToken,
  }) : _repository = repository,
       super(PdfReviewInitial()) {
    on<PdfReviewLoadRequested>(_onLoadRequested);
    on<PdfReviewSignatureSubmitted>(_onSignatureSubmitted);
  }

  Future<void> _onLoadRequested(
    PdfReviewLoadRequested event,
    Emitter<PdfReviewState> emit,
  ) async {
    emit(PdfReviewLoading());
    try {
      final pdfFile = await _repository.ReviewPdf(accessToken, documentId);
      // --- PERBAIKAN DI SINI ---
      // Menghapus tanda hubung (-) dari nama class State
      emit(PdfReviewLoadSuccess(pdfPath: pdfFile.path));
    } catch (e) {
      emit(
        PdfReviewLoadFailure(error: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  Future<void> _onSignatureSubmitted(
    PdfReviewSignatureSubmitted event,
    Emitter<PdfReviewState> emit,
  ) async {
    if (state is PdfReviewLoadSuccess) {
      final currentState = state as PdfReviewLoadSuccess;
      emit(currentState.copyWith(isSigning: true));
      try {
        final result = await _repository.processSignature(
          signToken,
          event.status,
        );
        emit(PdfReviewActionSuccess(message: result['message']));
      } catch (e) {
        emit(
          PdfReviewActionFailure(
            error: e.toString().replaceAll('Exception: ', ''),
          ),
        );
      } finally {
        emit(currentState.copyWith(isSigning: false));
      }
    }
  }
}
