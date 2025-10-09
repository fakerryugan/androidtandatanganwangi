import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:android/bottom_navbar/bottom_navbar.dart';
import 'package:android/bottom_navbar/home_bloc.dart';
import 'package:android/login/login_page.dart';
import 'package:android/login/bloc/login_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/loginsystem.dart';

import 'package:android/verifikasi/verifikasi.dart';

final GlobalKey<NavigatorState> navigatorkey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _requestPermission();
  _setupFCMListeners();
  runApp(const MyApp());
}

Future<void> _requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission();
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("Notifikasi diizinkan oleh pengguna.");
  } else {
    print("Pengguna menolak izin notifikasi.");
  }
}

void _setupFCMListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Menerima notifikasi saat aplikasi di foreground!");
    if (message.notification != null) {
      _showForegroundDialog(
        message.notification!.title,
        message.notification!.body,
        () => _handleMessage(message),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("Notifikasi ditekan saat aplikasi di background.");
    _handleMessage(message);
  });

  _checkInitialMessage();
}

// ✅ INI ADALAH FUNGSI KUNCI SEBAGAI "OTAK" NAVIGASI
void _handleMessage(RemoteMessage message) {
  final String? screen = message.data['target_screen'];
  final String? docId = message.data['document_id'];
  final String? signToken = message.data['sign_token'];
  final String? accessToken = message.data['access_token'];

  print("Mencoba navigasi ke: $screen dengan ID: $docId");

  if (screen == 'verification' &&
      docId != null &&
      signToken != null &&
      accessToken != null) {
    navigatorkey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => PdfReviewScreen(
          documentId: docId,
          signToken: signToken,
          accessToken: accessToken,
        ),
      ),
    );
  } else {
    print(
      "Data notifikasi tidak lengkap atau bukan untuk verifikasi. Data: ${message.data}",
    );
    navigatorkey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => NotificationScreen(
          message: message.notification?.body ?? "Tidak ada pesan",
        ),
      ),
    );
  }
}

void _checkInitialMessage() async {
  RemoteMessage? initialMessage = await FirebaseMessaging.instance
      .getInitialMessage();
  if (initialMessage != null) {
    print("Membuka aplikasi dari notifikasi yang sudah mati.");
    _handleMessage(initialMessage);
  }
}

void _showForegroundDialog(
  String? title,
  String? body,
  VoidCallback onActionPressed,
) {
  showDialog(
    context: navigatorkey.currentState!.overlay!.context,
    builder: (context) {
      return AlertDialog(
        title: Text(title ?? "Notifikasi Baru"),
        content: Text(body ?? "Anda menerima pesan baru."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog dulu
              onActionPressed(); // Lalu lakukan navigasi
            },
            child: const Text("Lihat"),
          ),
        ],
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final userMap = jsonDecode(userString);
      return userMap['token'] != null && userMap['token'].isNotEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(LoginRepository()),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc()..add(LoadHomeData()),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorkey,
        debugShowCheckedModeBanner: false,
        home: FutureBuilder<bool>(
          future: checkLoginStatus(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else {
              if (snapshot.data == true) {
                return const MyBottomNavBar();
              } else {
                return const LoginPage();
              }
            }
          },
        ),
      ),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  final String message;
  const NotificationScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifikasi")),
      body: Center(child: Text(message)),
    );
  }
}
