import 'dart:convert';
import 'package:http/http.dart' as http;

class Systemlogin {
  static Future<bool> login(String email, String password) async {
    final deviceId = "dummy_device_id_12345";

    final url = Uri.parse('http://127.0.0.1:8000/api/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_id': deviceId, // kirim device_id di body request
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
}
