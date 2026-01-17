import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Import for CookieManager
import '../../../core/model/model_user.dart';

class LoginRepository {
  final String baseUrl = "http://fakerryugan.my.id/api";
  
  // SHARED TOKEN: Kunci rahasia yang sama dengan di .env Laravel
  final String appSharedToken = "RAHASIA_NEGARA_123";

  Future<User?> syncSsoUser({
    required String username,
    required String password,
    required String nama,
    required String nim,
    // Cookies tidak wajib lagi di strategi ini, tapi kita biarkan parameter ini 
    // agar tidak merusak kontrak BLoC yang sudah ada.
    String cookies = "", 
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sync-sso'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nim': nim,
        'nama': nama,
        'username': username, // Opsional tergantung backend, kirim saja biar lengkap
        'app_token': appSharedToken, // <--- KUNCI UTAMA
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Asumsi respon backend: { "status": "success", "user": {..}, "access_token": "..." }
      return User.fromJson(data['user'], data['access_token']);
    } else {
      // Handle error (misal token salah atau server error)
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? "Login Gagal: ${response.statusCode}");
      } catch (_) {
        throw Exception("Gagal terhubung ke server: ${response.statusCode}");
      }
    }
  }

  Future<void> updateFcmToken(String tokenLogin, String fcmToken) async {
    await http.post(
      Uri.parse('$baseUrl/update-fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $tokenLogin',
      },
      body: jsonEncode({'fcm_token': fcmToken}),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    
    // Clear WebView Cookies (Agar tidak auto-login kembali ke SSO)
    try {
      final cookieManager = CookieManager.instance();
      await cookieManager.deleteAllCookies();
      print("WebView Cookies Cleared");
    } catch (e) {
      print("Failed to clear webview cookies: $e");
    }
  }
}
