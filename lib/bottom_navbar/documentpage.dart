import 'package:flutter/material.dart';

class Documentpage extends StatelessWidget {
  const Documentpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF9AD0EC), Color(0xFF6A85F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.grey,),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Satrio",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 1),
                  const Text(
                      "MAHASISWA",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                  ),
                ],
              ),
            ),

            Padding(padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProfileCard("NIM", "362358302007"),
                _buildProfileCard("Jabatan",
                    "Mahasiswa Teknologi Rekayasa Perangkat"),
                _buildProfileCard("No. Handphone", "098765433234"),
                _buildProfileCard("Alamat", "Rogojampi"),
              ],
            ),
      ),
      ],
    ),
    ),
    );
  }

  Widget _buildProfileCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 1),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}