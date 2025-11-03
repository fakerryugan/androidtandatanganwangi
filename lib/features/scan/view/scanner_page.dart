// lib/features/scanner/view/barcodescanner_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/scanner_bloc.dart';
import '../repository/scanner_repository.dart';
import '../view/scanner_view.dart';

class BarcodeScannerPage extends StatelessWidget {
  const BarcodeScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Sediakan Repository terlebih dahulu
    return RepositoryProvider(
      create: (context) => ScannerRepository(),
      child: BlocProvider(
        create: (context) => ScannerBloc(
          // 2. Sekarang BLoC bisa mengambil Repository dari context
          scannerRepository: context.read<ScannerRepository>(),
        )..add(ScanStarted()), // Langsung mulai scan saat BLoC dibuat
        child: const ScannerView(),
      ),
    );
  }
}
