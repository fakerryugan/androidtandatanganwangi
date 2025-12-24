import 'package:flutter/material.dart';
import 'package:android/ttd/gantittd.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool isNotificationOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Header Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFA3DAF7), Color(0xFF6E8CF7)], // Sesuaikan warna gradient
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

          // 2. Menu List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // --- Menu 1: Notification ---
                ListTile(
                  leading: const Icon(Icons.notifications_none, size: 28, color: Colors.black),
                  title: const Text(
                    'Notification',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Switch(
                    value: isNotificationOn,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.blue, // Warna biru toggle
                    onChanged: (value) {
                      setState(() {
                        isNotificationOn = value;
                      });
                    },
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(thickness: 0.5),
                ),

                // --- Menu 2: Ganti Tanda Tangan (BARU) ---
                ListTile(
                  leading: const Icon(Icons.edit_outlined, size: 28, color: Colors.black), // Icon pena
                  title: const Text(
                    'Ganti Tanda Tangan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  // Sesuai gambar, tidak ada panah di kanan, tapi item ini bisa diklik
                  onTap: () {
                    // Navigasi ke halaman Ganti Tanda Tangan
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangeSignaturePage(),
                      ),
                    );
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(thickness: 0.5),
                ),

                // --- Menu 3: Pusat Bantuan ---
                ListTile(
                  leading: const Icon(Icons.help_outline, size: 28, color: Colors.black),
                  title: const Text(
                    'Pusat Bantuan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                  onTap: () {
                    // Aksi ketika diklik
                  },
                ),
              ],
            ),
          ),

          // 3. Footer Version
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Versi aplikasi 2.1',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}