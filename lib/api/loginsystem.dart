// lib/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class Loginsystem {
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('http://127.0.0.1:8000/api/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': data};
    } catch (e) {
      return {
        'statusCode': 500,
        'data': {'message': 'Terjadi kesalahan: $e'},
      };
    }
  }
}
