part of 'files_bloc.dart';

abstract class FilesState extends Equatable {
  const FilesState();

  @override
  List<Object?> get props => [];
}

class FilesInitial extends FilesState {}

class FilesLoading extends FilesState {}

class FilesLoaded extends FilesState {
  final List<Map<String, dynamic>> allDocuments;
  final List<Map<String, dynamic>> filteredDocuments;
  final String
  selectedStatus; // Menyimpan status filter (cth: 'Semua', 'Pending')
  final String currentQuery; // Menyimpan kueri pencarian terakhir

  const FilesLoaded({
    required this.allDocuments,
    required this.filteredDocuments,
    this.selectedStatus = 'Semua', // Default 'Semua'
    this.currentQuery = '', // Default string kosong
  });

  FilesLoaded copyWith({
    List<Map<String, dynamic>>? allDocuments,
    List<Map<String, dynamic>>? filteredDocuments,
    String? selectedStatus,
    String? currentQuery,
  }) {
    return FilesLoaded(
      allDocuments: allDocuments ?? this.allDocuments,
      filteredDocuments: filteredDocuments ?? this.filteredDocuments,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      currentQuery: currentQuery ?? this.currentQuery,
    );
  }

  @override
  List<Object?> get props => [
    allDocuments,
    filteredDocuments,
    selectedStatus,
    currentQuery,
  ];
}

// State untuk Share
class FileReadyForSharing extends FilesState {
  final String tempFilePath; // Path file di cache
  final String originalName; // Nama file untuk teks share

  const FileReadyForSharing(this.tempFilePath, this.originalName);

  @override
  List<Object?> get props => [tempFilePath, originalName];
}

class FileShareFailure extends FilesState {
  final String message;
  const FileShareFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// State untuk Error umum
class FilesError extends FilesState {
  final String message;
  const FilesError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- STATE BARU UNTUK PROSES CANCEL ---
// State ini akan didengarkan oleh BlocListener di ArsipDokumenPage.dart

// 1. Sukses (Kasus 1: Soft Delete / Diarsipkan)
class FileCancelSuccess extends FilesState {
  final String message;
  const FileCancelSuccess(this.message);

  @override
  List<Object> get props => [message];
}

// 2. Sukses (Kasus 2: Permintaan pembatalan terkirim)
class FileCancelRequestSent extends FilesState {
  final String message;
  const FileCancelRequestSent(this.message);

  @override
  List<Object> get props => [message];
}

// 3. Gagal
class FileCancelFailure extends FilesState {
  final String message;
  const FileCancelFailure(this.message);

  @override
  List<Object> get props => [message];
}
// --- AKHIR STATE BARU ---