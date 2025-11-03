part of 'scanner_bloc.dart';

abstract class ScannerState extends Equatable {
  const ScannerState();

  @override
  List<Object> get props => [];
}

/// State awal, sebelum ada event yang dipicu.
class ScannerInitial extends ScannerState {}

/// State ketika aplikasi sedang memindai atau mengambil data.
class ScannerLoading extends ScannerState {}

/// State ketika data dokumen berhasil dimuat.
class ScannerLoadSuccess extends ScannerState {
  final Map<String, dynamic> documentData;

  const ScannerLoadSuccess(this.documentData);

  @override
  List<Object> get props => [documentData];
}

/// State ketika terjadi kegagalan (scan gagal, QR tidak valid, atau API error).
class ScannerLoadFailure extends ScannerState {
  final String error;

  const ScannerLoadFailure(this.error);

  @override
  List<Object> get props => [error];
}
