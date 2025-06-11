import 'package:shared_preferences/shared_preferences.dart';

class DocumentInfo {
  static const _docIdKey = 'uploaded_document_id';
  static const _accessTokenKey = 'document_access_token';

  static Future<void> save(int documentId, String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_docIdKey, documentId);
    await prefs.setString(_accessTokenKey, accessToken);
  }

  static Future<int?> getDocumentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_docIdKey);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_docIdKey);
    await prefs.remove(_accessTokenKey);
  }
}
