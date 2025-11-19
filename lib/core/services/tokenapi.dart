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
  Future<Map<String, dynamic>> cancelDocument(int documentId);
  Future<Map<String, dynamic>> uploadSigner({
    required int documentId,
    required String nip,
    String? alasan,
  });
  Future<Map<String, dynamic>> replaceDocument({
    required int documentId,
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

  // --- BARU: Metode untuk mengambil dokumen penolakan ---
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

  @override
  Future<Map<String, dynamic>> cancelDocument(int documentId) async {
    try {
      final response = await _dio.delete('/documents/cancel/$documentId');
      return {'success': true, ...response.data};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> uploadSigner({
    required int documentId,
    required String nip,
    String? alasan,
  }) async {
    try {
      final response = await _dio.post(
        '/add/$documentId',
        data: {'nip': nip, if (alasan != null) 'alasan': alasan},
      );
      return {'success': true, ...response.data};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> replaceDocument({
    required int documentId,
    required String filePath,
  }) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'pdf': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(
        '/documents/replace/$documentId',
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

  // --- IMPLEMENTASI BARU ---
  @override
  Future<List<Map<String, dynamic>>> fetchRejectionDocuments() async {
    try {
      // Menggunakan rute baru dari file Laravel Anda
      final response = await _dio.get('/signatures/cancellation-requests');
      // Asumsi struktur data sama dengan fetch lain (kunci 'documents')
      return List<Map<String, dynamic>>.from(response.data['documents'] ?? []);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<bool> approveCancellation(String signToken) async {
    try {
      // URL Base dan Token Auth sudah ditangani oleh _dio di constructor
      final response = await _dio.post(
        '/signatures/approve-cancellation/$signToken',
      );

      // Dio biasanya melempar error jika status code bukan 2xx
      // Jadi jika sampai sini, berarti sukses (200 OK)
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }
}
