import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:crm/models/models.dart';

class EmailService {
  Future<void> sendInvoiceEmail({
    required WorkItem item,
    required String pdfPath,
    bool attachPhotos = true,
    List<String> beforePhotoPaths = const [],
    List<String> afterPhotoPaths = const [],
  }) async {
    final recipient = item.email.trim();
    if (recipient.isEmpty) {
      throw Exception("Customer email is empty.");
    }

    final attachments = <String>[];

    if (pdfPath.trim().isNotEmpty && File(pdfPath).existsSync()) {
      attachments.add(pdfPath);
    }

    if (attachPhotos) {
      for (final p in beforePhotoPaths) {
        if (p.trim().isNotEmpty && File(p).existsSync()) {
          attachments.add(p);
        }
      }
      for (final p in afterPhotoPaths) {
        if (p.trim().isNotEmpty && File(p).existsSync()) {
          attachments.add(p);
        }
      }
    }

    final email = Email(
      subject: "Invoice - ${item.customerName} (${_shortId(item.id.toString())})",
      body: _emailBody(item),
      recipients: [recipient],
      attachmentPaths: attachments,
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } on PlatformException catch (e) {
      // 🚨 CRITICAL FIX: prevent app crash
      if (e.code == 'not_available') {
        throw Exception("No email app available on this device.");
      }
      rethrow;
    }
  }

  String _emailBody(WorkItem item) => """
Hi ${item.customerName},

Please find your invoice attached.

Work Item: ${_shortId(item.id.toString())}
Total: \$${item.total.toStringAsFixed(2)}

Thank you!
""";

  String _shortId(String id) =>
      id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();
}
