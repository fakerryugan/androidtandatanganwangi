import 'dart:async';
import 'package:android/core/services/tokenapi.dart'; // Pastikan path ini benar
import 'package:android/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:android/features/dashboard/view/dashboard_page.dart';
import 'package:android/features/filereviewverification/view/pdf_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart'; // <-- IMPORT BARU
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'firebase_options.dart';
import 'features/auth/repository/login_repository.dart';
import 'features/auth/view/login_page.dart';
import 'features/auth/bloc/login_bloc.dart';

final GlobalKey<NavigatorState> navigatorkey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // =================== BAGIAN YANG DIUBAH ===================
  // 1. Meminta Izin Notifikasi (FCM)
  await _requestFCMPermission();

  // 2. Meminta Izin Penyimpanan (Storage)
  await _requestStoragePermission();
  // ==========================================================

  _setupFCMListeners();
  runApp(const MyApp());
}

// ============== FUNGSI BARU UNTUK IZIN PENYIMPANAN ==============
Future<void> _requestStoragePermission() async {
  // Cek status izin saat ini
  var status = await Permission.storage.status;

  // Jika izin belum diberikan, maka minta
  if (!status.isGranted) {
    // Meminta izin kepada pengguna
    status = await Permission.storage.request();
    print("Storage Permission status: $status");

    // Jika pengguna menolak secara permanen, kita bisa tampilkan dialog
    // untuk mengarahkan pengguna ke pengaturan aplikasi.
    if (status.isPermanentlyDenied) {
      // Anda bisa membuat dialog di sini untuk memberitahu pengguna
      print(
        "Storage permission is permanently denied, cannot request permissions.",
      );
    }
  } else {
    print("Storage Permission already granted.");
  }
}

// =================== FCM (Nama fungsi diubah agar lebih jelas) ===================
Future<void> _requestFCMPermission() async {
  // Nama diubah dari _requestPermission
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission();
  print("FCM Permission: ${settings.authorizationStatus}");
}

// ... Sisa kode Anda dari sini ke bawah tidak perlu diubah ...
// (Saya sertakan lagi untuk kelengkapan)

void _setupFCMListeners() {
  FirebaseMessaging.onMessage.listen((message) {
    print("Foreground message received: ${message.notification?.title}");
    _showForegroundDialog(
      message.notification?.title,
      message.notification?.body,
      () => _handleMessage(message),
    );
  });

  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  _checkInitialMessage();
}

void _checkInitialMessage() async {
  RemoteMessage? initialMessage = await FirebaseMessaging.instance
      .getInitialMessage();
  if (initialMessage != null) _handleMessage(initialMessage);
}

void _handleMessage(RemoteMessage message) {
  final screen = message.data['target_screen'];
  final docId = message.data['document_id'];
  final signToken = message.data['sign_token'];
  final accessToken = message.data['access_token'];

  if (screen == 'verification' &&
      docId != null &&
      signToken != null &&
      accessToken != null) {
    navigatorkey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => PdfReviewScreen(
          documentId: docId,
          signToken: signToken,
          accessToken: accessToken,
        ),
      ),
    );
  } else {
    navigatorkey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => NotificationScreen(
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
  final context = navigatorkey.currentContext;
  if (context == null) return;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
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
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isDialogShown = false;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none) && !_isDialogShown) {
        _isDialogShown = true;
        _showNoInternetDialog();
      } else if (!results.contains(ConnectivityResult.none) && _isDialogShown) {
        final context = navigatorkey.currentContext;
        if (context != null && Navigator.of(context).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
          _isDialogShown = false;
        }
      }
    });
  }

  Future<void> _showNoInternetDialog() async {
    final context = navigatorkey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Koneksi Terputus"),
        content: const Text(
          "Tidak ada koneksi internet. Periksa jaringan Anda.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              var connectivityResult = await Connectivity().checkConnectivity();
              if (!connectivityResult.contains(ConnectivityResult.none)) {
                Navigator.pop(context);
                _isDialogShown = false;
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Masih tidak ada koneksi...")),
                );
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
    _subscription.cancel();
    super.dispose();
  }

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(create: (_) => LoginBloc(LoginRepository())),
        BlocProvider<DashboardBloc>(
          create: (_) => DashboardBloc(apiService: ApiServiceImpl()),
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
            }
            if (snapshot.hasData && snapshot.data == true) {
              return const DashboardPage();
            }
            return const LoginPage();
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
