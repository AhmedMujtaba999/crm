import 'dart:io';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../models.dart';

class EmailService {
  Future<void> sendInvoiceEmail({
    required WorkItem item,
    required String pdfPath,
    bool attachPhotos = true,

    // ✅ NEW
    List<String> beforePhotoPaths = const [],
    List<String> afterPhotoPaths = const [],
  }) async {
    final recipient = item.email.trim();
    if (recipient.isEmpty) throw Exception("Customer email is empty.");

    final attachments = <String>[];

    if (pdfPath.trim().isNotEmpty && File(pdfPath).existsSync()) {
      attachments.add(pdfPath);
    }

    if (attachPhotos) {
      for (final p in beforePhotoPaths) {
        final path = p.trim();
        if (path.isNotEmpty && File(path).existsSync()) attachments.add(path);
      }
      for (final p in afterPhotoPaths) {
        final path = p.trim();
        if (path.isNotEmpty && File(path).existsSync()) attachments.add(path);
      }
    }

    final subject = "Invoice - ${item.customerName} (${_shortId(item.id)})";
    final body = """
Hi ${item.customerName},

Please find your invoice attached.

Work Item: ${_shortId(item.id)}
Total: \$${item.total.toStringAsFixed(2)}

Thank you!
""";

    final email = Email(
      body: body,
      subject: subject,
      recipients: [recipient],
      attachmentPaths: attachments,
      isHTML: false,
    );

    await FlutterEmailSender.send(email);
  }

  String _shortId(String id) => id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();
}
