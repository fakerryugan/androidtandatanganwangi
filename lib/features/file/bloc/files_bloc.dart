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

    // --- PERUBAHAN ---
    // Mengganti on<DeleteFile> dengan on<CancelDocumentRequested>
    on<CancelDocumentRequested>(_onCancelDocumentRequested);
    // --- AKHIR PERUBAHAN ---
  }

  List<Map<String, dynamic>> _filterDocuments({
    required List<Map<String, dynamic>> allDocs,
    required String status,
    required String query,
  }) {
    final lowerQuery = query.toLowerCase();

    return allDocs.where((doc) {
      // 1. Cek Status
      final docStatus = doc['status'] ?? 'Pending';
      final bool statusMatch;
      if (status == 'Semua') {
        statusMatch = true;
      } else {
        // Ini memetakan 'Disetujui' (label UI) ke 'Diverifikasi' (data)
        // DAN juga mencocokkan 'Disetujui' jika ada di data.
        if (status == 'Disetujui') {
          statusMatch =
              (docStatus == 'Disetujui' || docStatus == 'Diverifikasi');
        } else {
          statusMatch = docStatus == status;
        }
      }

      // 2. Cek Kueri Pencarian
      final name = (doc['original_name'] ?? '').toLowerCase();
      final bool queryMatch = name.contains(lowerQuery);

      return statusMatch && queryMatch;
    }).toList();
  }

  Future<void> _onLoadAllUserFiles(
    LoadAllUserFiles event,
    Emitter<FilesState> emit,
  ) async {
    // ... (Tidak berubah)
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
    // ... (Tidak berubah)
    emit(FilesLoading());
    try {
      final documents = await _repository.getCompletedDocuments();
      emit(FilesLoaded(allDocuments: documents, filteredDocuments: documents));
    } catch (e) {
      emit(FilesError(e.toString()));
    }
  }

  void _onSearchFiles(SearchFiles event, Emitter<FilesState> emit) {
    // ... (Tidak berubah)
    if (state is FilesLoaded) {
      final currentState = state as FilesLoaded;

      final filtered = _filterDocuments(
        allDocs: currentState.allDocuments,
        status: currentState.selectedStatus,
        query: event.query,
      );

      emit(
        currentState.copyWith(
          filteredDocuments: filtered,
          currentQuery: event.query,
        ),
      );
    }
  }

  void _onFilterFilesByStatus(
    FilterFilesByStatus event,
    Emitter<FilesState> emit,
  ) {
    // ... (Tidak berubah)
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
    // ... (Tidak berubah)
    try {
      final tempFilePath = await _repository.prepareTempFile(
        accessToken: event.accessToken,
        encryptedName: event.encryptedName,
        originalName: event.originalName,
      );
      emit(FileReadyForSharing(tempFilePath, event.originalName));
    } catch (e) {
      emit(FileShareFailure('Gagal mempersiapkan file: ${e.toString()}'));
    }
  }

  // --- HANDLER BARU UNTUK CANCEL DOCUMENT ---
  // Menggantikan _onDeleteFile
  Future<void> _onCancelDocumentRequested(
    CancelDocumentRequested event,
    Emitter<FilesState> emit,
  ) async {
    // Kita tidak perlu state FilesLoaded, karena kita hanya emit state ephemeral
    // BlocListener di UI akan menangani feedback dan memuat ulang (reload)

    try {
      // 1. Panggil repository (INI PERBAIKANNYA)
      final response = await _repository.cancelDocument(
        event.documentId,
      ); // <-- TAMBAHKAN _repository.

      // 2. Cek respons dari API (sesuai logika DocumentController.php)
      // Cek apakah 'action' ada dan bernilai 'cancellation_request_sent'
      if (response['action'] == 'cancellation_request_sent') {
        // KASUS 2: Permintaan pembatalan dikirim
        emit(
          FileCancelRequestSent(
            response['message'] ?? 'Permintaan pembatalan telah dikirim.',
          ),
        );
      } else {
        // KASUS 1: Dokumen berhasil diarsipkan (soft delete)
        emit(
          FileCancelSuccess(
            response['message'] ?? 'Dokumen berhasil dibatalkan/diarsipkan.',
          ),
        );
      }
    } catch (e) {
      // 3. Jika gagal (cth: 404, 403, 500), emit state failure
      emit(
        FileCancelFailure(
          // Membersihkan "Exception: " dari pesan error
          e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  // --- AKHIR HANDLER BARU ---
}
