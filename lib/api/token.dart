import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

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

Future<List<Map<String, dynamic>>> fetchCompletedDocuments() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(
    'auth_token',
  ); 

  if (token == null) {
    print('Token tidak ditemukan');
    return []; 
  }

  final response = await http.get(
    Uri.parse('$baseUrl/documents/completed'), 
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['status'] == true && data['documents'] is List) {
      return List<Map<String, dynamic>>.from(data['documents']);
    } else {
      print('Format data tidak sesuai atau status false');
      return [];
    }
  } else {
    print('Gagal memuat dokumen: ${response.statusCode}');
    print('Response body: ${response.body}');
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
    
    // Debug
    print("Upload Response Code: ${response.statusCode}");
    print("Upload Response Body: $responseBody");

    final data = json.decode(responseBody);

    if (response.statusCode == 200) {
      if (data['access_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_document_token', data['access_token']);
      }

      return {
        'success': true,
        'access_token': data['access_token'],
        'security_code': data['security_code'] ?? 'SECURE123', // Fallback sementara
        'verification_url': data['verification_url'] ?? 'https://fakerryugan.my.id/verify/${data['access_token']}',
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

Future<Map<String, dynamic>> uploadSigner({
  required String accessToken, 
  required String nip,
  String? alasan,
  String? securityCode,
}) async {
  final token = await getToken(); 
  if (token == null) throw Exception('Token tidak ditemukan');

  try {
    // Debug URL
    final url = Uri.parse('$baseUrl/documents/$accessToken/signer');
    print("Adding Signer URL: $url");

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final body = {
      'nip': nip,
      if (alasan != null) 'tujuan': alasan,
      // FIX 422: Backend mewajibkan data posisi awal
      'page': 1,
      'x_pos': 0,
      'y_pos': 0,
      if (securityCode != null) 'security_code': securityCode,
    };

    print("Adding Signer Body: $body");

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    print("Adding Signer Response Code: ${response.statusCode}");
    print("Adding Signer Response Body: ${response.body}");

    final responseData = json.decode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'sign_token': responseData['sign_token'],
        'signer_id': responseData['signer_id'],
        'message': 'Penandatangan berhasil ditambahkan',
      };
    } else {
      final msg = responseData['message'] ?? 'Gagal menambahkan penandatangan';
      throw Exception("$msg (Error ${response.statusCode})");
    }
  } catch (e) {
    throw Exception('Error adding signer: ${e.toString()}');
  }
}


// FUNGSI BARU: Update Posisi Tanda Tangan
Future<void> updateSignaturePosition({
  required String signToken,
  required int page,
  required double x,
  required double y,
}) async {
  final token = await getToken();
  if (token == null) throw Exception('Token tidak ditemukan');

  try {
    // Sesuaikan endpoint Laravel Anda
    final url = Uri.parse('$baseUrl/documents/signer/update-position');
    
    final body = {
      'sign_token': signToken,
      'page': page,
      'x_position': x,
      'y_position': y,
    };

    // Debug
    print("Update Position Body: $body");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

   print("Update Position Response: ${response.statusCode} - ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Gagal update posisi: ${response.body}');
    }
  } catch (e) {
    print('Error update position: $e');
  }
}


Future<Map<String, dynamic>> replaceDocument({
  required String accessToken, 
  required String filePath,
}) async {
  final token = await getToken();
  if (token == null) throw Exception('Token tidak ditemukan');

  try {
    var uri = Uri.parse('$baseUrl/documents/replace/$accessToken');

    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';

    request.files.add(
      await http.MultipartFile.fromPath(
        'pdf',
        filePath,
        contentType: MediaType('application', 'pdf'),
      ),
    );

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = json.decode(responseBody);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'] ?? 'Dokumen berhasil dikirim!',
        'document_id':
            data['document_id'], 
      };
    } else {
      throw Exception(data['message'] ?? 'Gagal mengirim dokumen');
    }
  } catch (e) {
    throw Exception('Error saat mengganti dokumen: ${e.toString()}');
  }
}
