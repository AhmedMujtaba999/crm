import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crm/service_of_providers/pdf_service.dart';


class PdfPreviewProvider extends ChangeNotifier {
  final PdfService _service = PdfService();

  bool busy = false;

  Future<void> sharePdf(Uint8List bytes, String fileName) async {
    busy = true;
    notifyListeners();

    try {
      await _service.share(bytes: bytes, fileName: fileName);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> printPdf(Uint8List bytes) async {
    busy = true;
    notifyListeners();

    try {
      await _service.printPdf(bytes: bytes);
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
