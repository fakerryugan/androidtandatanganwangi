import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firebase_options.dart';
import 'features/auth/repository/login_repository.dart';
import 'features/auth/bloc/login_bloc.dart';
import 'features/auth/bloc/login_event.dart';
import 'features/auth/bloc/login_state.dart';
import 'features/auth/view/sso_webview_page.dart';
import 'features/dashboard/view/dashboard_page.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'core/services/tokenapi.dart'; // Sesuaikan dengan ApiServiceImpl Anda

final GlobalKey<NavigatorState> navigatorkey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inisialisasi Izin
  await _requestFCMPermission();
  await _requestStoragePermission();

  runApp(const MyApp());
}

Future<void> _requestStoragePermission() async {
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }
}

Future<void> _requestFCMPermission() async {
  await FirebaseMessaging.instance.requestPermission();
}

// --- WIDGET UTAMA ---
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
    // Monitor Koneksi Internet
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none) && !_isDialogShown) {
        _isDialogShown = true;
        _showNoInternetDialog();
      }
    });
  }

  void _showNoInternetDialog() {
    showDialog(
      context: navigatorkey.currentContext!,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Koneksi Terputus"),
        content: const Text("Periksa jaringan internet Anda."),
        actions: [
          TextButton(
            onPressed: () async {
              var res = await Connectivity().checkConnectivity();
              if (!res.contains(ConnectivityResult.none)) {
                Navigator.pop(navigatorkey.currentContext!);
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
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LoginBloc(LoginRepository())),
        BlocProvider(
          create: (_) => DashboardBloc(apiService: ApiServiceImpl()),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorkey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, primaryColor: Colors.blueAccent),
        // Menggunakan AppEntryGate sebagai gerbang utama
        home: const AppEntryGate(),
      ),
    );
  }
}

// --- GERBANG NAVIGASI (Mencegah Dirty Build Scope) ---
class AppEntryGate extends StatelessWidget {
  const AppEntryGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) async {
        if (state is LoginSuccess) {
          // 1. Simpan Token & FCM
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', state.user.token);

          String? fcmToken = await FirebaseMessaging.instance.getToken();
          await LoginRepository().updateFcmToken(
            state.user.token,
            fcmToken ?? "",
          );

          // 2. Navigasi setelah build selesai (Menghindari "Dirty Widget" error)
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
              (route) => false,
            );
          }
        } else if (state is LoginFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      child: SsoWebViewPage(
        onLoginSuccess: (u, p, n, nim, cookies) {
          context.read<LoginBloc>().add(
            LoginRequested(u, p, nama: n, nim: nim, cookies: cookies),
          );
        },
      ),
    );
  }
}

// --- DUMMY NOTIFICATION SCREEN ---
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
