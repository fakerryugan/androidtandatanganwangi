import 'dart:io';
import '../../../core/services/tokenapi.dart'; // Pastikan path ini benar

class FilesRepository {
  final ApiService _apiService;

  FilesRepository({required ApiService apiService}) : _apiService = apiService;

  Future<List<Map<String, dynamic>>> getAllUserDocuments() =>
      _apiService.fetchUserDocuments();

  Future<List<Map<String, dynamic>>> getCompletedDocuments() =>
      _apiService.fetchCompletedDocuments();

  Future<File> downloadPdf({
    required String accessToken,
    required String encryptedName,
    required String originalName,
  }) => _apiService.downloadDocument(accessToken, encryptedName, originalName);
}
