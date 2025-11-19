abstract class RejectionState {}

class RejectionInitial extends RejectionState {}

class RejectionLoading extends RejectionState {}

class RejectionLoaded extends RejectionState {
  final List<Map<String, dynamic>> allDocuments;
  final List<Map<String, dynamic>> filteredDocuments;

  RejectionLoaded({
    required this.allDocuments,
    required this.filteredDocuments,
  });

  RejectionLoaded copyWith({
    List<Map<String, dynamic>>? allDocuments,
    List<Map<String, dynamic>>? filteredDocuments,
  }) {
    return RejectionLoaded(
      allDocuments: allDocuments ?? this.allDocuments,
      filteredDocuments: filteredDocuments ?? this.filteredDocuments,
    );
  }
}

class RejectionError extends RejectionState {
  final String message;
  RejectionError(this.message);
}

// --- TAMBAHKAN STATE BARU INI ---
class RejectionActionSuccess extends RejectionState {
  final String message;
  RejectionActionSuccess(this.message);
}

class RejectionActionFailure extends RejectionState {
  final String error;
  RejectionActionFailure(this.error);
}
