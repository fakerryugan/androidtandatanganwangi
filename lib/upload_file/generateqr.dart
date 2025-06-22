import 'package:android/api/token.dart';
import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> showInputDialog({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required TextEditingController nipController,
  required TextEditingController tujuanController,
  required bool showTujuan,
  required int totalPages,
  required int documentId,
}) async {
  int selectedPage = 1;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Ditujukan untuk', textAlign: TextAlign.center),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tujuan Surat'),
              TextFormField(
                controller: tujuanController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan tujuan...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              Text('Ditujukan untuk'),
              TextFormField(
                controller: nipController,
                decoration: const InputDecoration(
                  hintText: 'Kepada...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedPage,
                decoration: const InputDecoration(
                  labelText: 'Halaman',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  totalPages,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Halaman ${i + 1}'),
                  ),
                ),
                onChanged: (val) {
                  if (val != null) selectedPage = val;
                },
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
              child: const Text('Kembali'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0A1E3F),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final nip = nipController.text.trim();
                  final alasan = tujuanController.text.trim();

                  try {
                    final result = await uploadSigner(
                      documentId: documentId,
                      nip: nip,
                      alasan: showTujuan ? alasan : null,
                    );

                    Navigator.pop(context, {
                      'sign_token': result['sign_token'],
                      'selected_page': selectedPage,
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
              child: const Text('OK'),
            ),
          ],
        ),
      ],
    ),
  );
}
