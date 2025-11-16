import '../../../core/services/tokenapi.dart'; // Pastikan path ini benar

class VerificationRepository {
  final ApiService _apiService;

  VerificationRepository({required ApiService apiService})
    : _apiService = apiService;

  // --- Metode Verifikasi ---
  Future<List<Map<String, dynamic>>> getVerificationDocuments() =>
      _apiService.fetchVerificationDocuments();

  Future<Map<String, dynamic>> processSignature(
    String signToken,
    String status,
  ) => _apiService.processSignature(signToken, status);

  // --- BARU: Metode Penolakan ---
  Future<List<Map<String, dynamic>>> getRejectionDocuments() =>
      _apiService.fetchRejectionDocuments();
}
