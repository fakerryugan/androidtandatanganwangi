import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Konfigurasi dan Helper Global ---
const String baseUrl = 'http://fakerryugan.my.id/api';

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

// --- Abstraksi Service Layer ---
abstract class ApiService {
  Future<Map<String, dynamic>?> fetchUserInfo();
  Future<List<Map<String, dynamic>>> fetchUserDocuments();
  Future<List<Map<String, dynamic>>> fetchCompletedDocuments();
  Future<File> downloadDocument(
    String accessToken,
    String encryptedName,
    String originalName,
  );
  Future<Map<String, dynamic>> uploadDocument(File file);

  // --- PERUBAHAN 1: documentId (int) -> accessToken (String) ---
  Future<Map<String, dynamic>> cancelDocument(
    String accessToken, {
    String? reason,
  });

  // --- PERUBAHAN 2: documentId (int) -> accessToken (String) ---
  Future<Map<String, dynamic>> uploadSigner({
    required String accessToken,
    required String nip,
    String? alasan,
  });

  // --- PERUBAHAN 3: documentId (int) -> accessToken (String) ---
  Future<Map<String, dynamic>> replaceDocument({
    required String accessToken,
    required String filePath,
  });

  Future<List<Map<String, dynamic>>> fetchVerificationDocuments();
  Future<File> downloadReviewPdf(String accessToken, String documentId);
  Future<Map<String, dynamic>> processSignature(
    String signToken,
    String status,
  );
  Future<String> downloadDocumentToCache(
    String accessToken,
    String encryptedName,
    String originalName,
  );

  Future<List<Map<String, dynamic>>> fetchRejectionDocuments();
  Future<bool> approveCancellation(String signToken);
}

// --- Implementasi Service Layer ---
class ApiServiceImpl implements ApiService {
  late final Dio _dio;

  ApiServiceImpl() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          return handler.next(options);
        },
      ),
    );
  }

  Exception _handleDioError(DioException e) {
    final errorResponse = e.response?.data;
    final message = errorResponse?['message'] ?? 'Terjadi kesalahan jaringan.';
    return Exception(message);
  }

  @override
  Future<Map<String, dynamic>?> fetchUserInfo() async {
    try {
      final response = await _dio.get('/auth');
      return response.data as Map<String, dynamic>;
    } on DioException {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserDocuments() async {
    try {
      final response = await _dio.get('/documents/user');
      return List<Map<String, dynamic>>.from(response.data['documents'] ?? []);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCompletedDocuments() async {
    try {
      final response = await _dio.get('/documents/completed');
      return List<Map<String, dynamic>>.from(response.data['documents'] ?? []);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<File> downloadDocument(
    String accessToken,
    String encryptedName,
    String originalName,
  ) async {
    final Directory? appDir = await getExternalStorageDirectory();

    if (appDir == null) {
      throw Exception(
        'Gagal menemukan direktori penyimpanan di perangkat ini.',
      );
    }

    final downloadsPath = '${appDir.path}/Downloads';
    await Directory(downloadsPath).create(recursive: true);

    final savePath = '$downloadsPath/$originalName';
    final url = '$baseUrl/documents/download/$accessToken/$encryptedName';

    try {
      await Dio().download(
        url,
        savePath,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return File(savePath);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> downloadDocumentToCache(
    String accessToken,
    String encryptedName,
    String originalName,
  ) async {
    final Directory tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/$originalName';
    final url = '$baseUrl/documents/download/$accessToken/$encryptedName';

    try {
      await Dio().download(
        url,
        savePath,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return savePath;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> uploadDocument(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post('/documents/upload', data: formData);
      return {'success': true, ...response.data};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- PERUBAHAN 1: Menggunakan Access Token ---
  @override
  // --- PERUBAHAN: Tambahkan parameter 'data' pada request delete ---
  @override
  Future<Map<String, dynamic>> cancelDocument(
    String accessToken, {
    String? reason,
  }) async {
    try {
      // URL disesuaikan: /documents/cancel/{accessToken}
      // Kita kirim 'reason' di dalam body JSON jika ada
      final response = await _dio.delete(
        '/documents/cancel/$accessToken',
        data: reason != null ? {'reason': reason} : null,
      );

      return {'success': true, ...response.data};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- PERUBAHAN 2: Menggunakan Access Token ---
  @override
  Future<Map<String, dynamic>> uploadSigner({
    required String accessToken,
    required String nip,
    String? alasan,
  }) async {
    try {
      // URL disesuaikan: /add/{accessToken}
      final response = await _dio.post(
        '/add/$accessToken',
        // Mengirim 'tujuan' jika 'alasan' diisi (mapping sesuai backend Laravel)
        data: {'nip': nip, if (alasan != null) 'tujuan': alasan},
      );
      return {'success': true, ...response.data};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // --- PERUBAHAN 3: Menggunakan Access Token ---
  @override
  Future<Map<String, dynamic>> replaceDocument({
    required String accessToken,
    required String filePath,
  }) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'pdf': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      // URL disesuaikan: /documents/replace/{accessToken}
      final response = await _dio.post(
        '/documents/replace/$accessToken',
        data: formData,
      );
      return {'success': true, ...response.data};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchVerificationDocuments() async {
    try {
      final response = await _dio.get('/signature/user');
      return List<Map<String, dynamic>>.from(response.data['documents'] ?? []);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<File> downloadReviewPdf(String accessToken, String documentId) async {
    try {
      final response = await _dio.post(
        '/documents/review/$accessToken',
        options: Options(responseType: ResponseType.bytes),
      );

      final dir = await getTemporaryDirectory();
      // documentId di sini hanya digunakan untuk penamaan file lokal
      final file = File('${dir.path}/document_$documentId.pdf');
      await file.writeAsBytes(response.data);
      return file;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> processSignature(
    String signToken,
    String status,
  ) async {
    try {
      final response = await _dio.post(
        '/documents/signature/$signToken',
        data: {'status': status},
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return e.response?.data;
      }
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRejectionDocuments() async {
    try {
      final response = await _dio.get('/signatures/cancellation-requests');
      return List<Map<String, dynamic>>.from(response.data['documents'] ?? []);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<bool> approveCancellation(String signToken) async {
    try {
      final response = await _dio.post(
        '/signatures/approve-cancellation/$signToken',
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
