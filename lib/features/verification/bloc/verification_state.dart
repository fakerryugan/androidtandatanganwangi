abstract class VerificationState {}

class VerificationInitial extends VerificationState {}

class VerificationLoading extends VerificationState {}

class VerificationLoaded extends VerificationState {
  final List<Map<String, dynamic>> allDocuments;
  final List<Map<String, dynamic>> filteredDocuments;

  VerificationLoaded({
    required this.allDocuments,
    required this.filteredDocuments,
  });

  VerificationLoaded copyWith({
    List<Map<String, dynamic>>? allDocuments,
    List<Map<String, dynamic>>? filteredDocuments,
  }) {
    return VerificationLoaded(
      allDocuments: allDocuments ?? this.allDocuments,
      filteredDocuments: filteredDocuments ?? this.filteredDocuments,
    );
  }
}

class VerificationError extends VerificationState {
  final String message;
  VerificationError(this.message);
}
