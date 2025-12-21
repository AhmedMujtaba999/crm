import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_email_sender/flutter_email_sender.dart';

import 'models.dart';
import 'storage.dart';
import 'widgets.dart';
import 'theme.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  bool attachPhotos = true;
  bool sendEmail = false;

  Future<(WorkItem, List<ServiceItem>)> _load(String id) async {
    final item = await AppDb.instance.getWorkItem(id);
    if (item == null) throw Exception("WorkItem not found");
    final services = await AppDb.instance.listServices(id);
    return (item, services);
  }

  Future<void> _pickPhoto(String workItemId, {required bool before}) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (x == null) return;

    await AppDb.instance.updatePhotos(
      workItemId: workItemId,
      beforePath: before ? x.path : null,
      afterPath: before ? null : x.path,
    );

    if (mounted) setState(() {});
  }

  Future<void> _deletePhoto(String workItemId, {required bool before}) async {
    await AppDb.instance.updatePhotos(
      workItemId: workItemId,
      beforePath: before ? "" : null,
      afterPath: before ? null : "",
    );
    if (mounted) setState(() {});
  }

  Future<File> _generatePdfInvoice(WorkItem item, List<ServiceItem> services) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Work Item Invoice", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("Date: ${DateFormat('y-MM-dd').format(item.createdAt)}"),
            pw.SizedBox(height: 10),
            pw.Text("Customer: ${item.customerName}"),
            pw.Text("Phone: ${item.phone}"),
            pw.Text("Email: ${item.email}"),
            pw.Text("Address: ${item.address}"),
            pw.SizedBox(height: 12),
            pw.Text("Services:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...services.map((s) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(s.name),
                    pw.Text("\$${s.amount.toStringAsFixed(2)}"),
                  ],
                )),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("\$${item.total.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/invoice_${item.id}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> _emailInvoice(WorkItem item, List<ServiceItem> services) async {
    if (item.email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Customer email is empty")));
      return;
    }

    // ✅ Realistic approach:
    // Mobile apps can't silently auto-send emails reliably.
    // We open email composer with PDF attached.
    final pdfFile = await _generatePdfInvoice(item, services);

    final email = Email(
      body: "Hi ${item.customerName},\n\nPlease find attached your invoice.\n\nThanks,\nPoolPro CRM",
      subject: "Invoice - ${item.customerName}",
      recipients: [item.email.trim()],
      attachmentPaths: [pdfFile.path],
      isHTML: false,
    );

    await FlutterEmailSender.send(email);

    // TODO BACKEND (Node.js) for true auto-send:
    // POST /send-invoice-email  {workItemId}
  }

  @override
  Widget build(BuildContext context) {
    final workItemId = (ModalRoute.of(context)?.settings.arguments ?? '') as String;

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(title: "Invoice Preview", showBack: true),
          Expanded(
            child: FutureBuilder<(WorkItem, List<ServiceItem>)>(
              future: _load(workItemId),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final (item, services) = snap.data!;
                final dateText = DateFormat('EEEE, MMMM d, y').format(item.createdAt);

                // handle empty-string deletes
                final beforePath = (item.beforePhotoPath != null && item.beforePhotoPath!.isNotEmpty) ? item.beforePhotoPath : null;
                final afterPath = (item.afterPhotoPath != null && item.afterPhotoPath!.isNotEmpty) ? item.afterPhotoPath : null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // invoice card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primary2],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.description_outlined, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text("Work Item Invoice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(dateText, style: const TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text("Customer Details", style: TextStyle(color: AppColors.subText, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(item.customerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(item.phone),
                            Text(item.email),
                            Text(item.address),
                            const Divider(height: 26),
                            const Text("Services", style: TextStyle(color: AppColors.subText, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            ...services.map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                      Text("\$${s.amount.toStringAsFixed(2)}"),
                                    ],
                                  ),
                                )),
                            const Divider(height: 26),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                Text("\$${item.total.toStringAsFixed(2)}",
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // photos + email options
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Checkbox(value: attachPhotos, onChanged: (v) => setState(() => attachPhotos = v ?? true)),
                              const Text("Attach Before/After Photos", style: TextStyle(fontWeight: FontWeight.w900)),
                            ]),
                            if (attachPhotos) ...[
                              const SizedBox(height: 10),
                              _photoBox(
                                title: "Before Photo",
                                path: beforePath,
                                onCapture: () => _pickPhoto(workItemId, before: true),
                                onDelete: () => _deletePhoto(workItemId, before: true),
                              ),
                              const SizedBox(height: 12),
                              _photoBox(
                                title: "After Photo",
                                path: afterPath,
                                onCapture: () => _pickPhoto(workItemId, before: false),
                                onDelete: () => _deletePhoto(workItemId, before: false),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(children: [
                              Checkbox(value: sendEmail, onChanged: (v) => setState(() => sendEmail = v ?? false)),
                              const Text("Send Email", style: TextStyle(fontWeight: FontWeight.w900)),
                            ]),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      GradientButton(
                        text: "Complete Work Item",
                        onTap: () async {
                          // Email compose (if checked)
                          if (sendEmail) {
                            await _emailInvoice(item, services);
                          }

                          // Complete status
                          await AppDb.instance.markCompleted(workItemId);

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Work item completed")));
                          Navigator.pop(context); // back to home
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoBox({
    required String title,
    required String? path,
    required VoidCallback onCapture,
    required VoidCallback onDelete,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.subText, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Stack(
          children: [
            InkWell(
              onTap: onCapture,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  color: AppColors.bg,
                ),
                child: path == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_outlined, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Capture Photo", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(File(path), fit: BoxFit.cover),
                      ),
              ),
            ),
            if (path != null)
              Positioned(
                right: 10,
                top: 10,
                child: InkWell(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}