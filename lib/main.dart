import 'dart:convert';
import 'package:android/bottom_navbar/bottom_navbar.dart';
import 'package:android/bottom_navbar/home_bloc.dart';
import 'package:android/login/login_page.dart';
import 'package:android/login/bloc/login_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api/loginsystem.dart';

void main() {
  runApp(const MyApp());
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
