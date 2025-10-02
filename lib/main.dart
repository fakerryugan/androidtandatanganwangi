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
    print("diijinkan");
  } else {
    print("tidak diijinkan");
  }
}

void _setupFCMListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      _showForegroundDialog(
        message.notification!.title,
        message.notification!.body,
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleMessage(message);
  });

  _checkInitialMessage();
}

void _handleMessage(RemoteMessage message) {
  navigatorkey.currentState?.push(
    MaterialPageRoute(
      builder: (context) {
        return NotificationScreen(
          message: message.notification?.body ?? "no message",
        );
      },
    ),
  );
}

void _checkInitialMessage() async {
  RemoteMessage? initialMessage = await FirebaseMessaging.instance
      .getInitialMessage();
  if (initialMessage != null) {
    _handleMessage(initialMessage);
  }
}

void _showForegroundDialog(String? title, String? body) {
  showDialog(
    context: navigatorkey.currentState!.overlay!.context,
    builder: (context) {
      return AlertDialog(
        title: Text(title ?? "no title"),
        content: Text(body ?? "no body"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ok"),
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
                return const MyBottomNavBar(); // ✅ Sudah login
              } else {
                return const LoginPage(); // ❌ Belum login
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
      appBar: AppBar(title: const Text("Notification")),
      body: Center(child: Text(message)),
    );
  }
}
