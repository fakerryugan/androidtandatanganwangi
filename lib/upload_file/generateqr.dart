import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> showInputDialog({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required TextEditingController nipController,
  required TextEditingController tujuanController,
  required bool showTujuan,
  required int totalPages,
}) async {
  int selectedPage = 1;

  return showDialog<Map<String, dynamic>>(
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
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: nipController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan NIP/NIM',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Masukkan NIP/NIM' : null,
              ),
              const SizedBox(height: 12),
              if (showTujuan) ...[
                const Text(
                  'Tujuan Surat',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                const SizedBox(height: 12),
              ],
              const Text('Pilih halaman tempat QR akan ditempatkan'),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: selectedPage,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: List.generate(
                  totalPages,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('Halaman ${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) selectedPage = value;
                },
              ),
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
          onPressed: () {
            if (formKey.currentState!.validate()) {
              final nip = nipController.text;
              final tujuan = tujuanController.text;

              // TODO: Ganti generate link QR di sini
              final encryptedLink =
                  '$nip-$tujuan-${DateTime.now().millisecondsSinceEpoch}';

              Navigator.pop(context, {
                'encrypted_link': encryptedLink,
                'selected_page': selectedPage - 1, // zero-based index
              });

              nipController.clear();
              tujuanController.clear();
            }
          },
          child: const Text('Generate QR'),
        ),
      ],
    ),
  );
}
