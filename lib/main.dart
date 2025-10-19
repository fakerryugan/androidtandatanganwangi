import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'firebase_options.dart';
import 'api/loginsystem.dart';
import 'package:android/login/login_page.dart';
import 'package:android/login/bloc/login_bloc.dart';
import 'package:android/bottom_navbar/bottom_navbar.dart';
import 'package:android/bottom_navbar/home_bloc.dart';
import 'package:android/verifikasi/verifikasi.dart';

final GlobalKey<NavigatorState> navigatorkey = GlobalKey<NavigatorState>();

// ====================================
// ============ MAIN =================
// ====================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _requestPermission();
  _setupFCMListeners();
  runApp(const MyApp());
}

// ====================================
// ============ FIREBASE ==============
// ====================================

Future<void> _requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission();
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("✅ Notifikasi diizinkan oleh pengguna.");
  } else {
    print("🚫 Pengguna menolak izin notifikasi.");
  }
}

void _setupFCMListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Notifikasi diterima saat aplikasi di foreground!");
    if (message.notification != null) {
      _showForegroundDialog(
        message.notification!.title,
        message.notification!.body,
        () => _handleMessage(message),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📬 Notifikasi ditekan saat aplikasi di background.");
    _handleMessage(message);
  });

  _checkInitialMessage();
}

void _checkInitialMessage() async {
  RemoteMessage? initialMessage = await FirebaseMessaging.instance
      .getInitialMessage();
  if (initialMessage != null) {
    print("🚀 Membuka aplikasi dari notifikasi yang sudah mati.");
    _handleMessage(initialMessage);
  }
}

void _handleMessage(RemoteMessage message) {
  final String? screen = message.data['target_screen'];
  final String? docId = message.data['document_id'];
  final String? signToken = message.data['sign_token'];
  final String? accessToken = message.data['access_token'];

  print("➡️ Navigasi ke: $screen dengan ID: $docId");

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
    print("⚠️ Data notifikasi tidak lengkap atau bukan untuk verifikasi.");
    navigatorkey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => NotificationScreen(
          message: message.notification?.body ?? "Tidak ada pesan",
        ),
      ),
    );
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
              Navigator.pop(context);
              onActionPressed();
            },
            child: const Text("Lihat"),
          ),
        ],
      );
    },
  );
}

// ====================================
// ======== APLIKASI UTAMA ============
// ====================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isDialogShown = false;

  @override
  void initState() {
    super.initState();

    // 🔔 Dengarkan perubahan koneksi internet
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;

      if (result == ConnectivityResult.none) {
        // Tidak ada koneksi → tampilkan popup
        if (!_isDialogShown) {
          _isDialogShown = true;
          _showNoInternetDialog();
        }
      } else {
        // Ada koneksi → tutup popup jika masih tampil
        if (_isDialogShown) {
          Navigator.of(
            navigatorkey.currentState!.overlay!.context,
            rootNavigator: true,
          ).pop();
          _isDialogShown = false;
        }
      }
    });
  }

  void _showNoInternetDialog() {
    showDialog(
      context: navigatorkey.currentState!.overlay!.context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Koneksi Terputus"),
        content: const Text(
          "Tidak ada koneksi internet. Periksa jaringan Anda.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              var results = await Connectivity().checkConnectivity();
              final result = results.isNotEmpty
                  ? results.first
                  : ConnectivityResult.none;

              if (result == ConnectivityResult.none) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Masih tidak ada koneksi...")),
                );
              } else {
                Navigator.pop(context);
                _isDialogShown = false;
              }
            },
            child: const Text("Coba Lagi"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

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

// ====================================
// ======== HALAMAN NOTIFIKASI ========
// ====================================

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
