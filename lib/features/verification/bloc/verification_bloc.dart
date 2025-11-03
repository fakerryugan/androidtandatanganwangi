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
    on<SearchVerificationDocuments>(_onSearchVerificationDocuments);
  }

  Future<void> _onLoadVerificationDocuments(
    LoadVerificationDocuments event,
    Emitter<VerificationState> emit,
  ) async {
    emit(VerificationLoading());
    try {
      final documents = await _repository.getVerificationDocuments();
      emit(
        VerificationLoaded(
          allDocuments: documents,
          filteredDocuments: documents,
        ),
      );
    } catch (e) {
      emit(VerificationError(e.toString()));
    }
  }

  void _onSearchVerificationDocuments(
    SearchVerificationDocuments event,
    Emitter<VerificationState> emit,
  ) {
    if (state is VerificationLoaded) {
      final currentState = state as VerificationLoaded;
      final query = event.query.toLowerCase();

      final filtered = currentState.allDocuments.where((doc) {
        final name = (doc['original_name'] ?? '').toLowerCase();
        return name.contains(query);
      }).toList();

      emit(currentState.copyWith(filteredDocuments: filtered));
    }
  }
}
