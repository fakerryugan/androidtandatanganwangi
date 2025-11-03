abstract class VerificationEvent {}

class LoadVerificationDocuments extends VerificationEvent {}

class SearchVerificationDocuments extends VerificationEvent {
  final String query;
  SearchVerificationDocuments(this.query);
}
