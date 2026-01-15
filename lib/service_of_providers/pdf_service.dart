import 'dart:typed_data';
import 'package:printing/printing.dart';

class PdfService {
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
  }) async {
    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
  }

  Future<void> printPdf({
    required Uint8List bytes,
  }) async {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
    );
  }
}
