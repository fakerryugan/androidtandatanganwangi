part of 'files_bloc.dart';

abstract class FilesEvent extends Equatable {
  const FilesEvent();

  @override
  List<Object> get props => [];
}

class LoadAllUserFiles extends FilesEvent {}

class LoadAllFiles extends FilesEvent {}

class SearchFiles extends FilesEvent {
  final String query;
  const SearchFiles(this.query);

  @override
  List<Object> get props => [query];
}

class FilterFilesByStatus extends FilesEvent {
  final String status;
  const FilterFilesByStatus(this.status);

  @override
  List<Object> get props => [status];
}

class ShareFile extends FilesEvent {
  final String accessToken;
  final String encryptedName;
  final String originalName;

  const ShareFile({
    required this.accessToken,
    required this.encryptedName,
    required this.originalName,
  });

  @override
  List<Object> get props => [accessToken, encryptedName, originalName];
}

class CancelDocumentRequested extends FilesEvent {
  final int documentId;
  const CancelDocumentRequested(this.documentId);

  @override
  List<Object> get props => [documentId];
}
