import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:android/bottom_navbar/bottom_navbar.dart'; // Sesuaikan path

class SignaturePage extends StatefulWidget {
  const SignaturePage({super.key});

  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  // Controller untuk mengatur canvas tanda tangan
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3, // Ketebalan pena
    penColor: Colors.black, // Warna tinta
    exportBackgroundColor: Colors.transparent, // Latar belakang saat disimpan
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Fungsi untuk menyimpan (Contoh: Konversi ke Bytes)
  Future<void> _handleSave() async {
    if (_controller.isNotEmpty) {
      // 1. Ambil data gambar
      final Uint8List? data = await _controller.toPngBytes();

      if (data != null) {
        // -----------------------------------------------------------
        // TODO: DI SINI KODE UPLOAD KE SERVER (API)
        // Biasanya kamu akan kirim 'data' ini ke API Backend
        // agar tersimpan di database pengguna.
        // -----------------------------------------------------------

        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tanda tangan berhasil disimpan! Masuk ke Home..."),
            backgroundColor: Colors.green,
          ),
        );

        // Jeda sebentar agar user sempat baca pesan (opsional)
        await Future.delayed(const Duration(seconds: 1));

        // 2. NAVIGASI KE HOME (BottomNavBar)
        // Gunakan pushReplacement agar user tidak bisa kembali ke halaman TTD
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyBottomNavBar()),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Area tanda tangan masih kosong!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // 1. Background Gradient Biru (Sesuai Desain)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFA3DAF7), // Biru Langit
              Color(0xFF6E8CF7),// Fade ke putih/biru sangat muda di bawah
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // 2. Header (Logo & Text)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    // Placeholder Logo (Ganti dengan Image.asset('assets/logo.png'))
                    Image.asset(
                      'assets/images/logo.png', // Pastikan path ini sesuai dengan folder Anda
                      height: 50,        // Menyamakan ukuran dengan kode sebelumnya
                      width: 50,
                      fit: BoxFit.contain, // Agar gambar tidak terpotong
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Atur Tanda Tanganmu\nSebelum Lanjut",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 3. Card Putih Utama
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Judul Card
                      Row(
                        children: const [
                          Icon(Icons.draw_outlined, color: Colors.black87), // Icon Pena
                          SizedBox(width: 8),
                          Text(
                            "Area Tanda Tangan Manual",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 4. Area Canvas Tanda Tangan
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBEBEB), // Warna abu-abu kanvas
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Signature(
                              controller: _controller,
                              backgroundColor: const Color(0xFFEBEBEB), // Samakan dengan container
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Center(
                        child: Text(
                          "Tanda tangan dengan jari di area di atas",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 5. Tombol Hapus & Simpan
                      Row(
                        children: [
                          // Tombol Hapus (Outlined Red)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _controller.clear();
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Hapus",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Tombol Simpan (Filled Green)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50), // Warna hijau
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Simpan",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Spacer bawah agar card tidak terlalu mepet bawah
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}