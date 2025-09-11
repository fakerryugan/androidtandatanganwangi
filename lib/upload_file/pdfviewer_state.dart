import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

enum PdfViewerStatus { initial, loaded, processing, success, error, sending }

class PdfViewerState extends Equatable {
  final PdfViewerStatus status;
  final String? filePath;
  final int? documentId;
  final List<Map<String, dynamic>> qrCodes;
  final String? error;
  final double? pageWidth; // Tambahkan ini
  final double? pageHeight; // Tambahkan ini

  const PdfViewerState({
    this.status = PdfViewerStatus.initial,
    this.filePath,
    this.documentId,
    this.qrCodes = const [],
    this.error,
    this.pageWidth,
    this.pageHeight,
  });

  @override
  List<Object?> get props => [status, filePath, documentId, qrCodes, error, pageWidth, pageHeight];

  PdfViewerState copyWith({
    PdfViewerStatus? status,
    String? filePath,
    int? documentId,
    List<Map<String, dynamic>>? qrCodes,
    String? error,
    double? pageWidth,
    double? pageHeight,
  }) {
    return PdfViewerState(
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      documentId: documentId ?? this.documentId,
      qrCodes: qrCodes ?? this.qrCodes,
      error: error,
      pageWidth: pageWidth ?? this.pageWidth,
      pageHeight: pageHeight ?? this.pageHeight,
    );
  }
}