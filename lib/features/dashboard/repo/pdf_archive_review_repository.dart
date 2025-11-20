import 'package:android/core/services/tokenapi.dart'; // Sesuaikan path file ApiService Anda

class PdfArchiveReviewRepository {
  final ApiService _apiService;

  // Kita gunakan Dependency Injection sederhana
  // Jika apiService tidak dikirim, otomatis pakai ApiServiceImpl default
  PdfArchiveReviewRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiServiceImpl();

  Future<String> downloadPdfForReview({
    required String accessToken,
    required String encryptedName,
    required String originalName,
  }) async {
    try {
      // --- "MENGAMBIL YANG PERLU" DARI API SERVICE ---
      // Kita menggunakan method ini karena sesuai dengan parameter yang ada
      // (accessToken, encryptedName, originalName) dan menyimpan ke Cache (Temp)
      final String filePath = await _apiService.downloadDocumentToCache(
        accessToken,
        encryptedName,
        originalName,
      );

      return filePath;
    } catch (e) {
      throw Exception('Gagal mendownload dokumen: $e');
    }
  }
}
