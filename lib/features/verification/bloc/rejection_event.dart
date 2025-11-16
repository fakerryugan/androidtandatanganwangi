// Lokasi: features/verification/bloc/rejection_event.dart

abstract class RejectionEvent {}

class LoadRejectionDocuments extends RejectionEvent {}

class SearchRejectionDocuments extends RejectionEvent {
  final String query;
  SearchRejectionDocuments(this.query);
}
