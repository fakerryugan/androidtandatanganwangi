import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class PdfViewerEvent extends Equatable {
  const PdfViewerEvent();

  @override
  List<Object> get props => [];
}

class LoadPdfViewer extends PdfViewerEvent {
  final String filePath;
  final int documentId;
  final Map<String, dynamic>? qrData;

  const LoadPdfViewer({
    required this.filePath,
    required this.documentId,
    this.qrData,
  });

  @override
  List<Object> get props => [filePath, documentId, qrData ?? ''];
}

class AddQrCode extends PdfViewerEvent {
  final Map<String, dynamic> qrData;
  const AddQrCode(this.qrData);

  @override
  List<Object> get props => [qrData];
}

class UpdateQrPosition extends PdfViewerEvent {
  final int qrIndex;
  final Offset newPosition;
  const UpdateQrPosition(this.qrIndex, this.newPosition);

  @override
  List<Object> get props => [qrIndex, newPosition];
}

class SaveAllQrCodesToPdf extends PdfViewerEvent {}

class SendDocument extends PdfViewerEvent {
  final String filePath;
  final int documentId;
  const SendDocument(this.filePath, this.documentId);

  @override
  List<Object> get props => [filePath, documentId];
}

class CancelDocument extends PdfViewerEvent {
  final int documentId;
  const CancelDocument(this.documentId);

  @override
  List<Object> get props => [documentId];
}

class ClearTempPdf extends PdfViewerEvent {}