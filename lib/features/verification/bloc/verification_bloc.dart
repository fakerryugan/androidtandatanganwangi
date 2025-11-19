import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/verification_repository.dart';

import 'Verification_event.dart';
import 'Verification_state.dart';

export 'Verification_event.dart';
export 'Verification_state.dart';

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final VerificationRepository _repository;

  VerificationBloc({required VerificationRepository repository})
    : _repository = repository,
      super(VerificationInitial()) {
    on<LoadVerificationDocuments>(_onLoadVerificationDocuments);
  }

  // --- HELPER: SORTING (Terbaru di Atas) ---
  List<Map<String, dynamic>> _sortDocumentsByDate(
    List<Map<String, dynamic>> docs,
  ) {
    // Buat salinan list agar tidak memodifikasi list asli secara langsung
    final sortedList = List<Map<String, dynamic>>.from(docs);

    sortedList.sort((a, b) {
      // Ambil tanggal upload (Ganti 'uploaded_at' sesuai key dari API Anda, misal 'created_at')
      final dateA =
          DateTime.tryParse(a['uploaded_at']?.toString() ?? '') ??
          DateTime(1970);
      final dateB =
          DateTime.tryParse(b['uploaded_at']?.toString() ?? '') ??
          DateTime(1970);

      // Bandingkan B ke A (Descending) agar yang terbaru ada di atas
      return dateB.compareTo(dateA);
    });

    return sortedList;
  }

  Future<void> _onLoadVerificationDocuments(
    LoadVerificationDocuments event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    try {
      final documents = await _repository.getVerificationDocuments();

      // URUTKAN DATA SEBELUM DI-EMIT
      final sortedDocs = _sortDocumentsByDate(documents);

      emit(
        VerificationLoaded(
          allDocuments: sortedDocs,
          filteredDocuments: sortedDocs,
        ),
      );
    } catch (e) {
      emit(VerificationError(e.toString()));
    }
  }
}
