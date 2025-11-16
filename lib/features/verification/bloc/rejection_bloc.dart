// Lokasi: features/verification/bloc/rejection_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/verification_repository.dart';
import 'rejection_event.dart';
import 'rejection_state.dart';

// Ekspor agar mudah diimpor di UI
export 'rejection_event.dart';
export 'rejection_state.dart';

class RejectionBloc extends Bloc<RejectionEvent, RejectionState> {
  final VerificationRepository _repository;

  RejectionBloc({required VerificationRepository repository})
    : _repository = repository,
      super(RejectionInitial()) {
    on<LoadRejectionDocuments>(_onLoadRejectionDocuments);
    on<SearchRejectionDocuments>(_onSearchRejectionDocuments);
  }

  Future<void> _onLoadRejectionDocuments(
    LoadRejectionDocuments event,
    Emitter<RejectionState> emit,
  ) async {
    emit(RejectionLoading());
    try {
      // Menggunakan metode repository yang baru
      final documents = await _repository.getRejectionDocuments();
      emit(
        RejectionLoaded(allDocuments: documents, filteredDocuments: documents),
      );
    } catch (e) {
      emit(RejectionError(e.toString()));
    }
  }

  void _onSearchRejectionDocuments(
    SearchRejectionDocuments event,
    Emitter<RejectionState> emit,
  ) {
    if (state is RejectionLoaded) {
      final currentState = state as RejectionLoaded;
      final query = event.query.toLowerCase();

      final filtered = currentState.allDocuments.where((doc) {
        // Sesuaikan 'original_name' jika key-nya berbeda di API penolakan
        final name = (doc['original_name'] ?? '').toLowerCase();
        return name.contains(query);
      }).toList();

      emit(currentState.copyWith(filteredDocuments: filtered));
    }
  }
}
