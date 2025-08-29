import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/model_user.dart';

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

      return User.fromJson(userData, token); // ✅ pakai token
    } else {
      throw Exception("Login gagal: ${response.body}");
    }
  }
}
