import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORT UNTUK FIREBASE ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart'; // Pastikan file ini ada setelah 'flutterfire configure'

// --- IMPORT HALAMAN-HALAMAN ANDA ---
import 'package:android/bottom_navbar/bottom_navbar.dart';
import 'package:android/bottom_navbar/home_bloc.dart';
import 'package:android/login/login_page.dart';
import 'package:android/login/bloc/login_bloc.dart';
import 'api/loginsystem.dart';
// import 'package:android/path/ke/halaman/detail_dokumen.dart'; // <-- GANTI DENGAN PATH YANG BENAR

// ===================================================================
// BAGIAN SETUP FIREBASE & NAVIGASI GLOBAL
// ===================================================================

/// Kunci global untuk mengontrol navigasi dari luar widget tree.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Fungsi untuk menangani navigasi saat notifikasi diklik.
void _handleMessageNavigation(Map<String, dynamic> data) {
  final String? docId = data['document_id'];
  final String? type = data['type'];

  if (type == 'document_received' && docId != null) {
    // Navigasi ke halaman detail dokumen menggunakan GlobalKey
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        // GANTI 'Scaffold' INI DENGAN NAMA WIDGET HALAMAN DETAIL DOKUMEN ANDA
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Dokumen Diterima')),
          body: Center(child: Text("Membuka Dokumen dengan ID: $docId")),
        ),
      ),
    );
  }
}

/// Mengatur semua listener untuk Firebase Cloud Messaging.
void setupFirebaseMessaging() {
  // Listener untuk notifikasi yang diklik saat aplikasi di-background.
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notifikasi diklik dari background!');
    _handleMessageNavigation(message.data);
  });

  // Mengecek notifikasi saat aplikasi dibuka dari keadaan terminated (ditutup total).
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print('Aplikasi dibuka dari notifikasi (terminated)!');
      _handleMessageNavigation(message.data);
    }
  });
}

// ===================================================================
// FUNGSI UTAMA APLIKASI (MAIN)
// ===================================================================

void main() async {
  // Memastikan Flutter siap sebelum menjalankan kode async.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Menginisialisasi Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Menjalankan setup untuk listener notifikasi.
  setupFirebaseMessaging();

  // Menjalankan aplikasi Flutter.
  runApp(const MyApp());
}

// ===================================================================
// WIDGET UTAMA APLIKASI (MYAPP)
// ===================================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Mengecek status login dari SharedPreferences.
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
        debugShowCheckedModeBanner: false,
        // Menghubungkan GlobalKey ke MaterialApp.
        navigatorKey: navigatorKey,
        home: FutureBuilder<bool>(
          future: checkLogin-Status(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else {
              if (snapshot.data == true) {
                return const MyBottomNavBar(); // ✅ Pengguna sudah login.
              } else {
                return const LoginPage(); // ❌ Pengguna belum login.
              }
            }
          },
        ),
      ),
    );
  }
}