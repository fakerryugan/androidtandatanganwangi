import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../repository/scanner_repository.dart'; // Sesuaikan path

part 'scanner_event.dart';
part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final ScannerRepository _scannerRepository;

  ScannerBloc({required ScannerRepository scannerRepository})
    : _scannerRepository = scannerRepository,
      super(ScannerInitial()) {
    on<ScanStarted>(_onScanStarted);
  }

  Future<void> _onScanStarted(
    ScanStarted event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerLoading());
    try {
      final scanResult = await _scannerRepository.scanBarcode();

      if (!scanResult.startsWith('http')) {
        emit(const ScannerLoadFailure('QR code tidak valid: bukan URL'));
        return;
      }

      final data = await _scannerRepository.getDocumentDetail(scanResult);
      emit(ScannerLoadSuccess(data));
    } catch (e) {
      emit(ScannerLoadFailure(e.toString()));
    }
  }
}
