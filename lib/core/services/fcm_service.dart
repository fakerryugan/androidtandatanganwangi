import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class FcmService {
  static Future<void> updateFcmToken(String tokenLogin) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    final url = Uri.parse('http://fakerryugan.my.id/api/update-fcm-token');
    await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $tokenLogin',
        'Content-Type': 'application/json',
      },
      body: '{"fcm_token": "$fcmToken"}',
    );
  }

  static Future<void> clearFcm() async {
    await FirebaseMessaging.instance.deleteToken();
  }
}
