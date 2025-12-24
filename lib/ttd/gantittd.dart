import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class ChangeSignaturePage extends StatefulWidget {
  const ChangeSignaturePage({super.key});

  @override
  State<ChangeSignaturePage> createState() => _ChangeSignaturePageState();
}

class _ChangeSignaturePageState extends State<ChangeSignaturePage> {
  // Controller tanda tangan
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_controller.isNotEmpty) {
      final Uint8List? data = await _controller.toPngBytes();

      if (data != null) {

        // 1. Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tanda tangan berhasil diperbarui!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1), // Durasi snackbar
          ),
        );

        // 2. Beri jeda sedikit agar user sempat membaca pesan sukses (Opsional)
        await Future.delayed(const Duration(seconds: 1));

        // 3. Kembali ke halaman Setting
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon buat tanda tangan baru terlebih dahulu."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Agar gradient menyentuh sampai status bar atas
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFA3DAF7), // Biru Langit
                  Color(0xFF6E8CF7), // Putih Kebiruan
                ],
              ),
            ),
          ),

          // 2. Konten Utama
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Header Judul (Icon Pena + Text)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center header
                    children: const [
                      Icon(Icons.edit_note, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        "Ganti Tanda Tangan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Card Putih
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label Area
                        Row(
                          children: const [
                            Icon(Icons.draw_outlined, color: Color(0xFF1A2342)),
                            SizedBox(width: 8),
                            Text(
                              "Area Tanda Tangan Manual",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2342),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Canvas Area
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBEBEB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Signature(
                                controller: _controller,
                                backgroundColor: const Color(0xFFEBEBEB),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            "Tanda tangan dengan jari di area di atas",
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tombol Action
                        Row(
                          children: [
                            // Tombol Hapus
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _controller.clear(),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Hapus",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Tombol Simpan
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleUpdate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  "Simpan",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}