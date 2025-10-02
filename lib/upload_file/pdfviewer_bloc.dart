// lib/pdf_viewer/bloc/pdf_viewer_bloc.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:android/api/token.dart'; // Sesuaikan dengan path API Anda
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

part 'pdfviewer_event.dart';
part 'pdfviewer_state.dart';

class PdfViewerBloc extends Bloc<PdfViewerEvent, PdfViewerState> {
  // Anda mungkin ingin memindahkan ini ke dalam repository/service
  final http.Client httpClient;

  PdfViewerBloc({required this.httpClient}) : super(const PdfViewerState()) {
    on<PdfViewerInitialized>(_onInitialized);
    on<SignatureAdded>(_onSignatureAdded);
    on<QrPositionUpdated>(_onQrPositionUpdated);
    on<QrCodesSavedToPdf>(_onQrCodesSavedToPdf);
    on<DocumentSent>(_onDocumentSent);
    on<DocumentCancelled>(_onDocumentCancelled);
  }

  void _onInitialized(
    PdfViewerInitialized event,
    Emitter<PdfViewerState> emit,
  ) {
    List<Map<String, dynamic>> initialQrCodes = [];
    if (event.qrData != null) {
      initialQrCodes.add({
        ...event.qrData!,
        'position': Offset(
          event.viewSize.width / 2 - 50,
          event.viewSize.height / 2 - 50,
        ),
        'locked': true,
      });
    }

    emit(
      state.copyWith(
        status: PdfStatus.loaded,
        currentPdfPath: event.filePath,
        documentId: event.documentId,
        qrCodes: initialQrCodes,
      ),
    );
  }

  void _onSignatureAdded(SignatureAdded event, Emitter<PdfViewerState> emit) {
    final newQrList = List<Map<String, dynamic>>.from(state.qrCodes);
    newQrList.add(event.newQrData);
    emit(state.copyWith(qrCodes: newQrList, status: PdfStatus.loaded));
  }

  void _onQrPositionUpdated(
    QrPositionUpdated event,
    Emitter<PdfViewerState> emit,
  ) {
    final updatedQrCodes = List<Map<String, dynamic>>.from(state.qrCodes);
    if (event.qrIndex < updatedQrCodes.length) {
      final qr = updatedQrCodes[event.qrIndex];
      qr['position'] = event.newPosition;
      qr['selected_page'] = event.pageNumber;
      emit(state.copyWith(qrCodes: updatedQrCodes));
    }
  }

  Future<void> _onQrCodesSavedToPdf(
    QrCodesSavedToPdf event,
    Emitter<PdfViewerState> emit,
  ) async {
    emit(state.copyWith(status: PdfStatus.saving));
    try {
      final originalFileBytes = await File(state.currentPdfPath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: originalFileBytes);
      final unlockedQrs = state.qrCodes
          .where((q) => q['locked'] != true)
          .toList();

      for (final qr in unlockedQrs) {
        // Logika pembuatan gambar QR dari kode asli
        final qrPainter = QrPainter.withQr(
          qr: QrValidator.validate(
            data: "${baseUrl}/view/${qr['sign_token']}",
            version: QrVersions.auto,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ).qrCode!,
          gapless: true,
        );
        final ui.Image qrImage = await qrPainter.toImage(100.0);
        final ByteData? byteData = await qrImage.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (byteData == null) continue;

        final Uint8List bytes = byteData.buffer.asUint8List();
        final PdfBitmap pdfImage = PdfBitmap(bytes);

        final int pageIndex = (qr['selected_page'] ?? 1) - 1;
        if (pageIndex < 0 || pageIndex >= document.pages.count) continue;

        final PdfPage pdfPage = document.pages[pageIndex];
        final Offset position = qr['position'] ?? Offset.zero;

        // Kalkulasi posisi berdasarkan ukuran view dan halaman PDF
        final Size pageSize = pdfPage.size;
        final Size viewSize = event.pdfViewerKey.currentContext!.size!;

        final double pdfX = (position.dx / viewSize.width) * pageSize.width;
        final double pdfY = (position.dy / viewSize.height) * pageSize.height;
        final double qrSizeInPdf = (100.0 / viewSize.width) * pageSize.width;

        pdfPage.graphics.drawImage(
          pdfImage,
          Rect.fromLTWH(
            pdfX.clamp(0, pageSize.width - qrSizeInPdf),
            pdfY.clamp(0, pageSize.height - qrSizeInPdf),
            qrSizeInPdf,
            qrSizeInPdf,
          ),
        );
      }

      // Simpan ke file sementara lalu rename
      final tempPath =
          '${Directory.systemTemp.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(tempPath).writeAsBytes(await document.save());
      document.dispose();

      // Ganti file lama dengan yang baru
      final oldFilePath = state.currentPdfPath;
      await File(tempPath).rename(oldFilePath);

      final lockedQrCodes = state.qrCodes
          .map((qr) => {...qr, 'locked': true})
          .toList();
      emit(state.copyWith(status: PdfStatus.loaded, qrCodes: lockedQrCodes));
    } catch (e) {
      emit(
        state.copyWith(status: PdfStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onDocumentSent(
    DocumentSent event,
    Emitter<PdfViewerState> emit,
  ) async {
    // 1. Set status ke 'sending'
    emit(state.copyWith(status: PdfStatus.sending));

    try {
      // 2. Panggil fungsi yang sudah dipindahkan ke token.dart
      final response = await replaceDocument(
        documentId: state.documentId,
        filePath: state.currentPdfPath,
      );

      // 3. Cek respons dan emit state yang sesuai
      if (response['success'] == true) {
        emit(
          state.copyWith(
            status: PdfStatus.success,
            successMessage: response['message'],
          ),
        ); // Opsional: tampilkan pesan sukses
      } else {
        // Sebenarnya blok ini tidak akan tereksekusi jika fungsi melempar Exception,
        // tapi ini sebagai pengaman.
        throw Exception(response['message'] ?? 'Gagal mengirim dokumen');
      }
    } catch (e) {
      // 4. Tangkap error jika terjadi dan emit state 'failure'
      emit(
        state.copyWith(status: PdfStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onDocumentCancelled(
    DocumentCancelled event,
    Emitter<PdfViewerState> emit,
  ) async {
    emit(state.copyWith(status: PdfStatus.loading, successMessage: null));
    try {
      final response = await cancelDocument(
        state.documentId,
      ); // Panggil fungsi API Anda
      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('document_id');
        emit(state.copyWith(status: PdfStatus.success, successMessage: null));
      } else {
        throw Exception(response['message'] ?? 'Gagal membatalkan dokumen');
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PdfStatus.failure,
          errorMessage: e.toString(),
          successMessage: null,
        ),
      );
    }
  }
}
