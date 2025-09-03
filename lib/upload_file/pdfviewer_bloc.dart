import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:bloc/bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:android/api/token.dart'; // Assume this file exists
import 'package:android/bottom_navbar/bottom_navbar.dart'; // Assume this file exists
import 'dart:convert';
import 'package:flutter/material.dart'; // For Offset

import 'pdfviewer_event.dart';
import 'pdfviewer_state.dart';

class PdfViewerBloc extends Bloc<PdfViewerEvent, PdfViewerState> {
  static const double qrPdfSize = 100.0;

  PdfViewerBloc() : super(const PdfViewerState()) {
    on<LoadPdfViewer>(_onLoadPdfViewer);
    on<AddQrCode>(_onAddQrCode);
    on<UpdateQrPosition>(_onUpdateQrPosition);
    on<SaveAllQrCodesToPdf>(_onSaveAllQrCodesToPdf);
    on<SendDocument>(_onSendDocument);
    on<CancelDocument>(_onCancelDocument);
  }

  void _onLoadPdfViewer(LoadPdfViewer event, Emitter<PdfViewerState> emit) {
    List<Map<String, dynamic>> qrCodes = [];
    if (event.qrData != null) {
      qrCodes.add({
        ...event.qrData!,
        'position': const Offset(0, 0), // Initial position, will be set by UI
        'locked': true,
      });
    }

    emit(state.copyWith(
      status: PdfViewerStatus.loaded,
      filePath: event.filePath,
      documentId: event.documentId,
      qrCodes: qrCodes,
    ));
  }

  void _onAddQrCode(AddQrCode event, Emitter<PdfViewerState> emit) {
    final updatedQrCodes = List<Map<String, dynamic>>.from(state.qrCodes);
    updatedQrCodes.add({
      ...event.qrData,
      'position': const Offset(0, 0), // Initial position, will be set by UI
      'locked': false,
    });
    emit(state.copyWith(
      status: PdfViewerStatus.loaded,
      qrCodes: updatedQrCodes,
    ));
  }

  void _onUpdateQrPosition(
      UpdateQrPosition event, Emitter<PdfViewerState> emit) {
    final updatedQrCodes = List<Map<String, dynamic>>.from(state.qrCodes);
    updatedQrCodes[event.qrIndex] = {
      ...updatedQrCodes[event.qrIndex],
      'position': event.newPosition,
    };
    emit(state.copyWith(qrCodes: updatedQrCodes));
  }

  Future<void> _onSaveAllQrCodesToPdf(
      SaveAllQrCodesToPdf event, Emitter<PdfViewerState> emit) async {
    emit(state.copyWith(status: PdfViewerStatus.processing));

    try {
      if (state.filePath == null) {
        throw Exception("File path is not set.");
      }

      final originalFileBytes = await File(state.filePath!).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: originalFileBytes);

      final unlockedQrs = state.qrCodes.where((q) => q['locked'] != true).toList();
      if (unlockedQrs.isEmpty) {
        emit(state.copyWith(
            status: PdfViewerStatus.loaded,
            error: 'No QR codes to save'));
        return;
      }

      for (final qr in unlockedQrs) {
        final qrPainter = QrPainter.withQr(
          qr: QrValidator.validate(
            data: "${baseUrl}/view/${qr['sign_token']}",
            version: QrVersions.auto,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
          ).qrCode!,
          gapless: true,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
        );

        final ui.Image qrImage = await qrPainter.toImage(qrPdfSize);
        final ByteData? byteData = await qrImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) continue;

        final Uint8List bytes = byteData.buffer.asUint8List();
        final PdfBitmap pdfImage = PdfBitmap(bytes);

        final int pageIndex = (qr['selected_page'] ?? 1) - 1;
        if (pageIndex < 0 || pageIndex >= document.pages.count) continue;

        final PdfPage pdfPage = document.pages[pageIndex];

        // Placeholder for position logic, should be handled by the UI
        final Offset position = qr['position'] ?? Offset.zero;

        // This requires a reference to the PDF viewer's size and zoom, which
        // is tricky in BLoC. You might need to pass this info as part of the event.
        // For a true BLoC approach, the UI would handle this logic and pass
        // the final PDF coordinates to the BLoC.
        // For simplicity, let's assume a direct mapping for now.
        pdfPage.graphics.drawImage(
          pdfImage,
          Rect.fromLTWH(
            position.dx,
            position.dy,
            qrPdfSize,
            qrPdfSize,
          ),
        );
      }

      final tempPath = '${(await getTemporaryDirectory()).path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(tempPath);
      await file.writeAsBytes(await document.save());
      document.dispose();

      await File(state.filePath!).delete();
      await file.rename(state.filePath!);

      final updatedQrCodes = state.qrCodes.map((qr) => {...qr, 'locked': true}).toList();

      emit(state.copyWith(
        status: PdfViewerStatus.loaded,
        qrCodes: updatedQrCodes,
      ));
    } catch (e) {
      emit(state.copyWith(status: PdfViewerStatus.error, error: e.toString()));
    }
  }

  Future<void> _onSendDocument(SendDocument event, Emitter<PdfViewerState> emit) async {
    emit(state.copyWith(status: PdfViewerStatus.sending));

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      if (authToken == null) throw Exception('Token tidak valid');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/documents/replace/${event.documentId}'),
      );
      request.headers['Authorization'] = 'Bearer $authToken';
      request.files.add(
        await http.MultipartFile.fromPath(
          'new_file',
          event.filePath,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        emit(state.copyWith(status: PdfViewerStatus.success));
      } else {
        throw Exception(jsonDecode(responseBody)['message'] ?? 'Gagal mengirim dokumen');
      }
    } catch (e) {
      emit(state.copyWith(status: PdfViewerStatus.error, error: e.toString()));
    }
  }

  Future<void> _onCancelDocument(CancelDocument event, Emitter<PdfViewerState> emit) async {
    emit(state.copyWith(status: PdfViewerStatus.processing));

    try {
      final response = await cancelDocument(event.documentId);
      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('document_id');
        emit(state.copyWith(status: PdfViewerStatus.success));
      } else {
        throw Exception(response['message'] ?? 'Gagal membatalkan dokumen');
      }
    } catch (e) {
      emit(state.copyWith(status: PdfViewerStatus.error, error: e.toString()));
    }
  }
}