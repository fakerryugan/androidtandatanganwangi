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
      title: const Text('Input Tanda Tangan'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nipController,
                decoration: const InputDecoration(
                  labelText: 'NIP/NIM',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 10),
              if (showTujuan)
                TextFormField(
                  controller: tujuanController,
                  decoration: const InputDecoration(
                    labelText: 'Alasan / Tujuan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Wajib diisi' : null,
                ),
              const SizedBox(height: 10),
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
                onChanged: (val) => selectedPage = val ?? 1,
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
              final nip = nipController.text.trim();
              final tujuan = tujuanController.text.trim();
              final payload =
                  '$nip-$tujuan-${DateTime.now().millisecondsSinceEpoch}';

              Navigator.pop(context, {
                'encrypted_link': payload,
                'selected_page': selectedPage - 1,
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
