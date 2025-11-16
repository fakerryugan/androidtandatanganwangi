import 'package:android/features/dashboard/view/dashboard_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../repository/login_repository.dart';

class LoginmasukPage extends StatefulWidget {
  const LoginmasukPage({super.key});

  @override
  State<LoginmasukPage> createState() => _LoginmasukPageState();
}

class _LoginmasukPageState extends State<LoginmasukPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 60,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              margin: const EdgeInsets.only(top: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53935),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    key: const Key('okkk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 40,
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              child: CircleAvatar(
                backgroundColor: const Color(0xFFE53935),
                radius: 40,
                child: const Icon(Icons.close, color: Colors.white, size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.05;
    final logoSize = size.width * 0.22;

    return BlocProvider(
      create: (_) => LoginBloc(LoginRepository()),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) async {
            if (state is LoginSuccess) {
              String? fcmToken = await FirebaseMessaging.instance.getToken();
              print("Token FCM user: $fcmToken");
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('token', state.user.token);
              await LoginRepository().updateFcmToken(
                state.user.token,
                fcmToken ?? "",
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              );
            } else if (state is LoginFailure) {
              _showErrorDialog('Login Gagal', state.error);
            }
          },
          builder: (context, state) {
            final isLoading = state is LoginLoading;

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(127, 146, 248, 1),
                    Color.fromRGBO(175, 219, 248, 1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: logoSize,
                          height: logoSize,
                          child: Image.asset('assets/images/logo.png'),
                        ),
                        SizedBox(height: size.height * 0.03),
                        const Text(
                          'SELAMAT DATANG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: size.height * 0.01),
                        const Text(
                          'APLIKASI DOKUMEN & TANDA TANGAN DIGITAL',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'POLITEKNIK NEGERI BANYUWANGI',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.05),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 20,
                          ),
                          child: Column(
                            children: [
                              TextField(
                                key: const Key('username_field'),
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: size.height * 0.03),
                              TextField(
                                key: const Key('password_field'),
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: size.height * 0.03),
                              SizedBox(
                                width: double.infinity,

                                child: ElevatedButton(
                                  key: const Key('login_button_masuk'),
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          final username = _usernameController
                                              .text
                                              .trim();
                                          final password =
                                              _passwordController.text;

                                          if (username.isEmpty ||
                                              password.isEmpty) {
                                            _showErrorDialog(
                                              'Salah',
                                              'Username dan Password harus diisi tidak boleh kosong',
                                            );
                                            return;
                                          }

                                          context.read<LoginBloc>().add(
                                            LoginRequested(username, password),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    padding: EdgeInsets.symmetric(
                                      vertical: size.height * 0.02,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          'Masuk',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
