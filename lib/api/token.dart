import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Ganti sesuai base URL kamu
const String baseUrl = 'http://fakerryugan.my.id/api';

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

Future<Map<String, dynamic>?> fetchUserInfo() async {
  final token = await getToken();
  if (token == null) return null;

  final response = await http.get(
    Uri.parse('$baseUrl/auth'),
    headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    return null;
  }
}

Future<List<Map<String, dynamic>>> fetchUserDocuments() async {
  final token = await getToken();
  if (token == null) return [];

  final response = await http.get(
    Uri.parse('$baseUrl/documents/user'),
    headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['documents']);
  } else {
    return [];
  }
}

Future<Map<String, dynamic>?> uploadSigner({
  required int documentId,
  required String nip,
  String? alasan,
  required String token,
}) async {
  final uri = Uri.parse(
    'http://fakerryugan.my.id/api/documents/$documentId/add-signer',
  );

  final response = await http.post(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'nip': nip,
      if (alasan != null && alasan.isNotEmpty) 'alasan': alasan,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    final message = jsonDecode(response.body)['message'];
    throw Exception(message);
  }
}
