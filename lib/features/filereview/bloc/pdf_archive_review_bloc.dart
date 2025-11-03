import 'package:android/features/filereview/reponsitory/pdf_archive_review_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'pdf_archive_review_event.dart';
part 'pdf_archive_review_state.dart';

class PdfArchiveReviewBloc
    extends Bloc<PdfArchiveReviewEvent, PdfArchiveReviewState> {
  final PdfArchiveReviewRepository _repository;
  final String accessToken;
  final String encryptedName;

  PdfArchiveReviewBloc({
    required PdfArchiveReviewRepository repository,
    required this.accessToken,
    required this.encryptedName,
  }) : _repository = repository,
       super(PdfArchiveReviewInitial()) {
    on<PdfArchiveReviewLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    PdfArchiveReviewLoadRequested event,
    Emitter<PdfArchiveReviewState> emit,
  ) async {
    emit(PdfArchiveReviewLoading());
    try {
      final pdfFile = await _repository.loadArchivePdf(
        accessToken,
        encryptedName,
      );
      emit(PdfArchiveReviewLoadSuccess(pdfPath: pdfFile.path));
    } catch (e) {
      emit(
        PdfArchiveReviewLoadFailure(
          error: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}
