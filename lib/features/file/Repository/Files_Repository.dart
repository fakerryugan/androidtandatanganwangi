import '../../../core/services/tokenapi.dart';

class FilesRepository {
  final ApiService _apiService;

  FilesRepository({required ApiService apiService}) : _apiService = apiService;

  Future<List<Map<String, dynamic>>> getAllUserDocuments() =>
      _apiService.fetchUserDocuments();

  Future<List<Map<String, dynamic>>> getCompletedDocuments() =>
      _apiService.fetchCompletedDocuments();

  Future<String> prepareTempFile({
    required String accessToken,
    required String encryptedName,
    required String originalName,
  }) async {
    try {
      final String filePath = await _apiService.downloadDocumentToCache(
        accessToken,
        encryptedName,
        originalName,
      );
      return filePath;
    } catch (e) {
      throw Exception('Gagal mempersiapkan file untuk share: $e');
    }
  }

  Future<Map<String, dynamic>> cancelDocument(int documentId) async {
    try {
      // Panggil metode cancelDocument dari ApiService
      final response = await _apiService.cancelDocument(documentId);
      return response;
    } catch (e) {
      // Teruskan error agar BLoC/UI bisa menangkapnya
      throw Exception('Gagal membatalkan dokumen: $e');
    }
  }
}
