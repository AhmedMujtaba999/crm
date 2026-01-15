import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfPreviewPage extends StatelessWidget {
  const PdfPreviewPage({
    super.key,
    required this.title,
    required this.fileName,
    required this.pdfBytes,
  });

  final String title;
  final String fileName;
  final Uint8List pdfBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: (_) async => pdfBytes,
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}
