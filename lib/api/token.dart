import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
    return jsonDecode(response.body);
  } else {
    print('Gagal fetch user info: ${response.body}');
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
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data['documents']);
  } else {
    print('Gagal fetch dokumen: ${response.body}');
    return [];
  }
}

Future<http.Response?> downloadDocument(
  String accessToken,
  String encryptedName,
) async {
  try {
    final uri = Uri.parse(
      '$baseUrl/documents/download/$accessToken/$encryptedName',
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return response;
    } else {
      print('Gagal download: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error download: $e');
    return null;
  }
}

Future<Map<String, dynamic>?> uploadDocument(File file) async {
  final token = await getToken();
  if (token == null) throw Exception('Token tidak ditemukan');

  var uri = Uri.parse('$baseUrl/documents/upload');
  var request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token'
    ..files.add(await http.MultipartFile.fromPath('file', file.path));

  var response = await request.send();
  final responseBody = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    return json.decode(responseBody);
  } else {
    final body = json.decode(responseBody);
    throw Exception(body['message'] ?? 'Gagal upload: ${response.statusCode}');
  }
}

Future<Map<String, dynamic>?> uploadSigner({
  required int documentId,
  required String nip,
  String? alasan, // optional kalau tidak wajib
}) async {
  final token = await getToken();

  final url = Uri.parse('$baseUrl/add/$documentId');

  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  final body = {'nip': nip, if (alasan != null) 'alasan': alasan};

  final response = await http.post(
    url,
    headers: headers,
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return {'sign_token': data['sign_token'], 'signer_id': data['signer_id']};
  } else if (response.statusCode == 409) {
    throw Exception('Penandatangan sudah ditambahkan');
  } else {
    final data = jsonDecode(response.body);
    throw Exception(data['message'] ?? 'Gagal menambahkan penandatangan');
  }
}
