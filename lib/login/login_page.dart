import 'package:android/login/loginmasuk_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.04; // 4% dari lebar layar
    final containerHeight = size.height * 0.25; // 25% dari tinggi layar
    final logoSize = size.width * 0.22; // logo proporsional

    return Scaffold(
      body: Container(
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
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                    width: double.infinity,
                    height: containerHeight,
                    margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          SizedBox(height: containerHeight * 0.13),
                          const Text(
                            'Silahkan klik login untuk masuk ke aplikasi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 70, 70, 70),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: containerHeight * 0.25),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              key: const Key('login_button_awal'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginmasukPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Login',
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
