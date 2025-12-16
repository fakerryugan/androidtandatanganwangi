import 'package:android/api/token.dart'; // Pastikan path ini benar
import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> showInputDialog({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required TextEditingController nipController,
  required TextEditingController tujuanController,
  required bool showTujuan, // Parameter penentu visible
  required int totalPages,
  required String accessToken, // <-- String Access Token
}) async {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Tambah Penandatangan', textAlign: TextAlign.center),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HANYA TAMPIL JIKA showTujuan == true
              if (showTujuan) ...[
                const Text('Tujuan Surat'),
                TextFormField(
                  key: const Key('tujuan_field'),
                  controller: tujuanController,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan tujuan surat...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Tujuan wajib diisi' : null,
                ),
                const SizedBox(height: 12),
              ],

              const Text('Ditujukan untuk (NIP)'),
              TextFormField(
                key: const Key('nip_field'),
                controller: nipController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Masukkan NIP...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'NIP wajib diisi' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0A1E3F),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              key: const Key('dialog_ok_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0A1E3F),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final nip = nipController.text.trim();

                  // Ambil alasan hanya jika showTujuan true
                  final alasan = showTujuan
                      ? tujuanController.text.trim()
                      : null;

                  try {
                    // Pastikan uploadSigner di api/token.dart menerima parameter ini
                    final result = await uploadSigner(
                      accessToken: accessToken,
                      nip: nip,
                      alasan: alasan,
                    );

                    Navigator.pop(context, {
                      'success': true,
                      'sign_token': result['sign_token'],
                    });

                    nipController.clear();
                    tujuanController.clear();
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
