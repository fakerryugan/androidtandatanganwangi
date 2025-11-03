import 'package:equatable/equatable.dart'; // Impor Equatable
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/files_repository.dart';

part 'files_event.dart';
part 'files_state.dart';

class FilesBloc extends Bloc<FilesEvent, FilesState> {
  final FilesRepository _repository;

  FilesBloc({required FilesRepository repository})
    : _repository = repository,
      super(FilesInitial()) {
    on<LoadAllFiles>(_onLoadAllFiles);
    on<LoadCompletedFiles>(_onLoadCompletedFiles);
    on<SearchFiles>(_onSearchFiles);
    on<DownloadFile>(_onDownloadFile);
  }

  Future<void> _onLoadAllFiles(
    LoadAllFiles event,
    Emitter<FilesState> emit,
  ) async {
    emit(FilesLoading());
    try {
      final documents = await _repository.getAllUserDocuments();
      emit(FilesLoaded(allDocuments: documents, filteredDocuments: documents));
    } catch (e) {
      emit(FilesError(e.toString()));
    }
  }

  Future<void> _onLoadCompletedFiles(
    LoadCompletedFiles event,
    Emitter<FilesState> emit,
  ) async {
    emit(FilesLoading());
    try {
      final documents = await _repository.getCompletedDocuments();
      emit(FilesLoaded(allDocuments: documents, filteredDocuments: documents));
    } catch (e) {
      emit(FilesError(e.toString()));
    }
  }

  void _onSearchFiles(SearchFiles event, Emitter<FilesState> emit) {
    if (state is FilesLoaded) {
      final currentState = state as FilesLoaded;
      final query = event.query.toLowerCase();

      final filtered = currentState.allDocuments.where((doc) {
        final name = (doc['original_name'] ?? '').toLowerCase();
        return name.contains(query);
      }).toList();

      emit(currentState.copyWith(filteredDocuments: filtered));
    }
  }

  Future<void> _onDownloadFile(
    DownloadFile event,
    Emitter<FilesState> emit,
  ) async {
    try {
      // Panggil metode yang sudah diperbarui
      await _repository.downloadPdf(
        accessToken: event.accessToken,
        encryptedName: event.encryptedName,
        originalName: event.originalName,
      );

      // Berikan pesan sukses yang lebih jelas
      emit(
        FileDownloadSuccess(
          'Dokumen "${event.originalName}" berhasil diunduh ke folder Downloads.',
        ),
      );
    } catch (e) {
      emit(FileDownloadFailure('Gagal mengunduh file: ${e.toString()}'));
    }
  }
}
