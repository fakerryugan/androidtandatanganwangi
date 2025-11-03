part of 'files_bloc.dart';

// Tambahkan Equatable ke State agar lebih mudah di-test dan dibandingkan
abstract class FilesState extends Equatable {
  const FilesState();

  @override
  List<Object?> get props => [];
}

class FilesInitial extends FilesState {}

class FilesLoading extends FilesState {}

class FilesLoaded extends FilesState {
  // `allDocuments` adalah daftar master asli dari API
  final List<Map<String, dynamic>> allDocuments;
  // `filteredDocuments` adalah yang ditampilkan di UI (setelah pencarian)
  final List<Map<String, dynamic>> filteredDocuments;

  const FilesLoaded({
    required this.allDocuments,
    required this.filteredDocuments,
  });

  FilesLoaded copyWith({
    List<Map<String, dynamic>>? allDocuments,
    List<Map<String, dynamic>>? filteredDocuments,
  }) {
    return FilesLoaded(
      allDocuments: allDocuments ?? this.allDocuments,
      filteredDocuments: filteredDocuments ?? this.filteredDocuments,
    );
  }

  @override
  List<Object?> get props => [allDocuments, filteredDocuments];
}

class FileDownloadSuccess extends FilesState {
  final String message;

  const FileDownloadSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class FileDownloadFailure extends FilesState {
  final String message;

  const FileDownloadFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class FilesError extends FilesState {
  final String message;
  const FilesError(this.message);

  @override
  List<Object?> get props => [message];
}
