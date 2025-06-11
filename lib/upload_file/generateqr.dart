import 'package:android/api/dokumen.dart';
import 'package:android/api/token.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> showInputDialog({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required TextEditingController nipController,
  required TextEditingController tujuanController,
  required bool showTujuan,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ditujukan Untuk'),
      content: IntrinsicWidth(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NIP/NIM',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: nipController,
                decoration: const InputDecoration(
                  hintText: 'NIP/NIM',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Masukkan NIP/NIM' : null,
              ),
              const SizedBox(height: 12),
              if (showTujuan) ...[
                const Text(
                  'Tujuan surat',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: tujuanController,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan tujuan surat',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Masukkan tujuan' : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              final nip = nipController.text.trim();
              final alasan = tujuanController.text.trim();
              final documentId = await DocumentInfo.getDocumentId();
              final token = await getToken();

              if (documentId == null || token == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dokumen belum ditemukan')),
                );
                return;
              }

              final url = Uri.parse(
                '$baseUrl/documents/$documentId/add-signer',
              );

              try {
                final body = {'nip': nip, if (showTujuan) 'alasan': alasan};

                final response = await http.post(
                  url,
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode(body),
                );

                final responseData = jsonDecode(response.body);

                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        responseData['message'] ?? 'Berhasil ditambahkan',
                      ),
                    ),
                  );
                  Navigator.pop(context);
                  nipController.clear();
                  if (showTujuan) tujuanController.clear();
                } else if (response.statusCode == 409) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        responseData['message'] ??
                            'Penandatangan sudah ditambahkan',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menambahkan: ${responseData['message'] ?? 'Terjadi kesalahan'}',
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Terjadi kesalahan: $e')),
                );
              }
            }
          },
          child: const Text('generate qr'),
        ),
      ],
    ),
  );
}
