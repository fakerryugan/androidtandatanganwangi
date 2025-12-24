import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/model/model_user.dart';

class LoginRepository {
  final String baseUrl = "http://fakerryugan.my.id/api";

  Future<User?> syncSsoUser({
    required String username,
    required String password,
    required String nama,
    required String nim,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sync-sso'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'nama': nama,
        'nim': nim,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['user'], data['access_token']);
    }
    throw Exception(
      jsonDecode(response.body)['message'] ?? "Gagal Sinkronisasi Server",
    );
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
}
