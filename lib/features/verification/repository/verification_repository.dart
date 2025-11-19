import '../../../core/services/tokenapi.dart';

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

  // --- Metode Penolakan ---
  Future<List<Map<String, dynamic>>> getRejectionDocuments() =>
      _apiService.fetchRejectionDocuments();

  // PERBAIKAN DI SINI: Hubungkan ke ApiService
  Future<bool> approveCancellation(String signToken) =>
      _apiService.approveCancellation(signToken);
}
