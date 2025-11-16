import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/view/login_page.dart';
import '../../auth/bloc/login_bloc.dart';
import '../../auth/bloc/login_state.dart';
import '../../auth/bloc/login_event.dart';

class MenuSettings extends StatefulWidget {
  const MenuSettings({super.key});

  @override
  State<MenuSettings> createState() => _MenuSettingsState();
}

class _MenuSettingsState extends State<MenuSettings> {
  bool isNotificationOn = true;

  @override
  Widget build(BuildContext context) {
    // Asumsi LoginBloc disediakan di atas DashboardPage (misal di main.dart)
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LogoutSuccess || state is LoginInitial) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 50, bottom: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFA3DAF7), Color(0xFF6E8CF7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Pengaturan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications, size: 28),
                        title: const Text(
                          'Notification',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Switch(
                          value: isNotificationOn,
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.blue,
                          onChanged: (value) {
                            setState(() {
                              isNotificationOn = value;
                            });
                          },
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.help_outline, size: 28),
                        title: const Text(
                          'Pusat Bantuan',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Aksi ketika diklik
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          size: 28,
                          color: Colors.red,
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        onTap: () {
                          // Panggil event dari LoginBloc
                          context.read<LoginBloc>().add(LogoutRequested());
                        },
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Versi aplikasi 0.1',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
