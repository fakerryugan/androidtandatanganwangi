abstract class RejectionEvent {}

class LoadRejectionDocuments extends RejectionEvent {}

class SearchRejectionDocuments extends RejectionEvent {
  final String query;
  SearchRejectionDocuments(this.query);
}

// UPDATE BAGIAN INI
class ApproveRejectionDocument extends RejectionEvent {
  final String signToken; // Ubah dari documentId ke signToken
  ApproveRejectionDocument(this.signToken);
}
