import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android/bottom_navbar/bottom_navbar.dart';
import 'package:android/login/bloc/login_bloc.dart';
import 'package:android/login/bloc/login_event.dart';
import 'package:android/login/bloc/login_state.dart';
import 'package:android/api/loginsystem.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(LoginRepository()),
      child: Scaffold(
        body: BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) async {
            if (state is LoginSuccess) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('token', state.user.token);

              debugPrint("LOGIN BERHASIL. Pindah ke BottomNavBar...");
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MyBottomNavBar()),
              );
            } else if (state is LoginFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error)));
            }
          },
          builder: (context, state) {
            final isLoading = state is LoginLoading;

            return Container(
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
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 87,
                          height: 86,
                          child: Image.asset('assets/images/logo.png'),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'SELAMAT DATANG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 43),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 20,
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 30),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton(
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
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Username dan Password harus diisi',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        context.read<LoginBloc>().add(
                                          LoginRequested(username, password),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 60,
                                    vertical: 15,
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
