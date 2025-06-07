import 'package:flutter/material.dart';

Future<void> showInputDialog({
  required BuildContext context,
  required GlobalKey<FormState> formKey,
  required TextEditingController nipController,
  required TextEditingController tujuanController,
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
                'Ditujukan untuk',
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

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('NIP/NIM: $nip, Tujuan: $tujuan')),
              );

              Navigator.pop(context);
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
