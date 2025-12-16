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
  final String selectedStatus;
  final String currentQuery;

  const FilesLoaded({
    required this.allDocuments,
    required this.filteredDocuments,
    this.selectedStatus = 'Semua',
    this.currentQuery = '',
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

class FileReadyForSharing extends FilesState {
  final String tempFilePath;
  final String originalName;

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

class FilesError extends FilesState {
  final String message;
  const FilesError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- STATE UNTUK CANCEL ---

class FileCancelProcessing extends FilesState {
  final String fileName;
  const FileCancelProcessing(this.fileName);

  @override
  List<Object> get props => [fileName];
}

class FileCancelSuccess extends FilesState {
  final String message;
  const FileCancelSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class FileCancelRequestSent extends FilesState {
  final String message;
  final String? fileName;

  // PERBAIKAN DI SINI: Hapus 'this.' yang berlebihan
  const FileCancelRequestSent(this.message, {this.fileName});

  @override
  List<Object?> get props => [message, fileName];
}

class FileCancelFailure extends FilesState {
  final String message;
  const FileCancelFailure(this.message);

  @override
  List<Object> get props => [message];
}
