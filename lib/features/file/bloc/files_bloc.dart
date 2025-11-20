import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/files_repository.dart';

part 'files_event.dart';
part 'files_state.dart';

class FilesBloc extends Bloc<FilesEvent, FilesState> {
  final FilesRepository _repository;

  FilesBloc({required FilesRepository repository})
    : _repository = repository,
      super(FilesInitial()) {
    on<LoadAllUserFiles>(_onLoadAllUserFiles);
    on<LoadAllFiles>(_onLoadAllFiles);
    on<SearchFiles>(_onSearchFiles);
    on<ShareFile>(_onShareFile);
    on<FilterFilesByStatus>(_onFilterFilesByStatus);
    on<CancelDocumentRequested>(_onCancelDocumentRequested);
  }

  List<Map<String, dynamic>> _filterDocuments({
    required List<Map<String, dynamic>> allDocs,
    required String status,
    required String query,
  }) {
    final lowerQuery = query.toLowerCase().trim();
    // Jika query tidak kosong, aktifkan mode SEARCHING (Abaikan Tab Status)
    final isSearching = lowerQuery.isNotEmpty;

    return allDocs.where((doc) {
      // 1. Cek Nama File
      final originalNameRaw = doc['original_name'];
      final nameStr = (originalNameRaw != null)
          ? originalNameRaw.toString().toLowerCase()
          : '';
      final bool queryMatch = nameStr.contains(lowerQuery);

      // JIKA SEDANG MENCARI: Return hasil match nama saja (Cari di semua tab)
      if (isSearching) {
        return queryMatch;
      }

      // JIKA TIDAK MENCARI: Filter berdasarkan Tab Status
      final docStatusRaw = doc['status'];
      final docStatus = (docStatusRaw != null)
          ? docStatusRaw.toString()
          : 'Pending';

      if (status == 'Semua') return true;

      if (status == 'Disetujui') {
        return (docStatus == 'Disetujui' || docStatus == 'Diverifikasi');
      }

      return docStatus == status;
    }).toList();
  }

  Future<void> _onLoadAllUserFiles(
    LoadAllUserFiles event,
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

  Future<void> _onLoadAllFiles(
    LoadAllFiles event,
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

      // Pindah visual tab ke 'Semua' jika sedang mencari
      final targetStatus = event.query.isNotEmpty
          ? 'Semua'
          : currentState.selectedStatus;

      final filtered = _filterDocuments(
        allDocs: currentState.allDocuments,
        status: targetStatus,
        query: event.query,
      );

      emit(
        currentState.copyWith(
          filteredDocuments: filtered,
          currentQuery: event.query,
          selectedStatus: targetStatus,
        ),
      );
    }
  }

  void _onFilterFilesByStatus(
    FilterFilesByStatus event,
    Emitter<FilesState> emit,
  ) {
    if (state is FilesLoaded) {
      final currentState = state as FilesLoaded;

      final filtered = _filterDocuments(
        allDocs: currentState.allDocuments,
        status: event.status,
        query: currentState.currentQuery,
      );

      emit(
        currentState.copyWith(
          filteredDocuments: filtered,
          selectedStatus: event.status,
        ),
      );
    }
  }

  Future<void> _onShareFile(ShareFile event, Emitter<FilesState> emit) async {
    final currentState = state; // Simpan state agar list tidak hilang
    try {
      final tempFilePath = await _repository.prepareTempFile(
        accessToken: event.accessToken,
        encryptedName: event.encryptedName,
        originalName: event.originalName,
      );
      emit(FileReadyForSharing(tempFilePath, event.originalName));

      // Restore State agar UI kembali normal setelah share muncul
      if (currentState is FilesLoaded) emit(currentState);
    } catch (e) {
      emit(FileShareFailure('Gagal: ${e.toString()}'));
      if (currentState is FilesLoaded) emit(currentState);
    }
  }

  Future<void> _onCancelDocumentRequested(
    CancelDocumentRequested event,
    Emitter<FilesState> emit,
  ) async {
    final currentState = state; // Simpan state
    try {
      final response = await _repository.cancelDocument(event.documentId);

      if (response['action'] == 'cancellation_request_sent') {
        emit(
          FileCancelRequestSent(
            response['message'] ?? 'Permintaan terkirim.',
            fileName: response['fileName'],
          ),
        );
        if (currentState is FilesLoaded) emit(currentState);
      } else {
        emit(FileCancelSuccess(response['message'] ?? 'Berhasil.'));
      }
    } catch (e) {
      emit(FileCancelFailure(e.toString().replaceAll('Exception: ', '')));
      if (currentState is FilesLoaded) emit(currentState);
    }
  }
}
