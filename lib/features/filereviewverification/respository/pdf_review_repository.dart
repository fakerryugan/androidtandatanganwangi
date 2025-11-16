// lib/features/filereviewverification/respository/pdf_review_repository.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:android/api/token.dart';

class PdfReviewRepository {
  Future<File> ReviewPdf(String accessToken, String documentId) async {
    final token = await getToken();
    if (token == null) throw Exception("Token not found");

    final response = await http.post(
      Uri.parse('$baseUrl/documents/review/$accessToken'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/pdf'},
    );

    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/document_$documentId.pdf');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to load PDF');
    }
  }

  Future<Map<String, dynamic>> processSignature(
    String signToken,
    String status, {
    String? comment,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception("Token not found");

    final response = await http.post(
      Uri.parse('$baseUrl/documents/signature/$signToken'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': status, 'comment': comment}),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 409) {
      return responseData;
    } else {
      throw Exception(responseData['message'] ?? 'Failed to process signature');
    }
  }
}
