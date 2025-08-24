import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool isNotificationOn = true;
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
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
            child: Center(
              child: Text('Pengaturan', style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ListTile(
                leading: const Icon(Icons.notifications, size: 28),
                title: Text('Notification',
                  style: TextStyle(
                      fontWeight: FontWeight.w600),
                ),
                trailing: Switch(
                  value: isNotificationOn,
                  activeColor: Colors.white,
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
                title: Text(
                  'Pusat Bantuan',
                  style: TextStyle(
                      fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Aksi ketika diklik
                },
              ),
            ],
          ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Versi aplikasi 0.1',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

