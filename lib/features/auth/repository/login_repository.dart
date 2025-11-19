import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/model/model_user.dart';

class LoginRepository {
  final String baseUrl = "http://fakerryugan.my.id/api";

  Future<User?> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      final userData = data['user'];
      return User.fromJson(userData, token);
    } else {
      throw Exception("Kredensial ini tidak cocok dengan catatan kami.");
    }
  }

  Future<void> updateFcmToken(String tokenLogin, String fcmToken) async {
    final url = Uri.parse('$baseUrl/update-fcm-token');
    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $tokenLogin',
      },
      body: jsonEncode({'fcm_token': fcmToken}),
    );
  }
}
