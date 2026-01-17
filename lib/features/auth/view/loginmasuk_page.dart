import 'package:android/features/auth/bloc/login_bloc.dart';
import 'package:android/features/auth/bloc/login_event.dart';
import 'package:android/features/auth/bloc/login_state.dart';
import 'package:android/features/auth/repository/login_repository.dart';
import 'package:android/features/auth/view/sso_webview_page.dart';
import 'package:android/features/dashboard/view/dashboard_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginmasukPage extends StatelessWidget {
  const LoginmasukPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(LoginRepository()),
      child: Scaffold(
        body: BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) async {
            if (state is LoginSuccess) {
              // Jalankan FCM & Sinkronisasi Storage
              String? fcm = await FirebaseMessaging.instance.getToken();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('token', state.user.token);
              await LoginRepository().updateFcmToken(
                state.user.token,
                fcm ?? "",
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              );
            }
          },
          builder: (context, state) {
            return Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7F92F8), Color(0xFFAFDBF8)],
                  begin: Alignment.topCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', width: 100),
                  const SizedBox(height: 20),
                  const Text(
                    "SELAMAT DATANG",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      "APLIKASI DOKUMEN DIGITAL POLIWANGI",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: state is LoginLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => SsoWebViewPage(
                                    onLoginSuccess: (u, p, n, nim, cookies) {
                                      context.read<LoginBloc>().add(
                                        LoginRequested(u, p, nama: n, nim: nim, cookies: cookies),
                                      );
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                ),
                              );
                            },
                      child: state is LoginLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              "MASUK DENGAN SSO",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
