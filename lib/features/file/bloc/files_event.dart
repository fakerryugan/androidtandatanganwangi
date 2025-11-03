part of 'files_bloc.dart';

abstract class FilesEvent extends Equatable {
  const FilesEvent();

  @override
  List<Object> get props => [];
}

class LoadAllFiles extends FilesEvent {}

class LoadCompletedFiles extends FilesEvent {}

class SearchFiles extends FilesEvent {
  final String query;
  const SearchFiles(this.query); // Tambahkan const

  @override
  List<Object> get props => [query];
}

class DownloadFile extends FilesEvent {
  final String accessToken;
  final String encryptedName; // <-- Ubah dari documentId
  final String originalName;

  const DownloadFile({
    required this.accessToken,
    required this.encryptedName, // <-- Ubah dari documentId
    required this.originalName,
  });

  @override
  List<Object> get props => [accessToken, encryptedName, originalName];
}
