import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'http://fakerryugan.my.id/api';

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

Future<int?> getDocumentId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('document_id');
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

Future<Map<String, dynamic>> uploadDocument(File file) async {
  final token = await getToken();
  if (token == null) throw Exception('Token tidak ditemukan');

  try {
    var uri = Uri.parse('$baseUrl/documents/upload');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = json.decode(responseBody);

    if (response.statusCode == 200) {
      // Save document_id to SharedPreferences
      if (data['document_id'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('document_id', data['document_id']);
      }

      return {
        'success': true,
        'document_id': data['document_id'],
        'file_path': data['file_path'] ?? '',
        'message': data['message'] ?? 'Upload berhasil',
      };
    } else {
      throw Exception(
        data['message'] ?? 'Gagal upload: ${response.statusCode}',
      );
    }
  } catch (e) {
    throw Exception('Error uploading document: ${e.toString()}');
  }
}

Future<Map<String, dynamic>> cancelDocument(int documentId) async {
  try {
    final token = await getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final response = await http.delete(
      Uri.parse('$baseUrl/documents/cancel/$documentId'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    final responseData = json.decode(response.body);

    if (response.statusCode == 200) {
      // Remove document_id from SharedPreferences on successful cancellation
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('document_id');

      return {
        'success': true,
        'message': responseData['message'] ?? 'Document cancelled successfully',
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to cancel document',
      };
    }
  } catch (e) {
    return {'success': false, 'message': 'Network error: ${e.toString()}'};
  }
}

Future<Map<String, dynamic>> uploadSigner({
  required int documentId,
  required String nip,
  String? alasan,
}) async {
  final token = await getToken();
  if (token == null) throw Exception('Token tidak ditemukan');

  try {
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

    final responseData = json.decode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'sign_token': responseData['sign_token'],
        'signer_id': responseData['signer_id'],
        'message': 'Penandatangan berhasil ditambahkan',
      };
    } else {
      throw Exception(
        responseData['message'] ?? 'Gagal menambahkan penandatangan',
      );
    }
  } catch (e) {
    throw Exception('Error adding signer: ${e.toString()}');
  }
}
