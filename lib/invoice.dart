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

  WorkItem? _item;
  List<ServiceItem> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final id = ModalRoute.of(context)!.settings.arguments as String;

    final item = await AppDb.instance.getWorkItem(id);
    final services = await AppDb.instance.listServices(id);

    if (!mounted) return;

    setState(() {
      _item = item;
      _services = services;
      _loading = false;
    });
  }

  // ---------------- PHOTOS ----------------

  Future<void> _pickPhoto({required bool before}) async {
    if (_item == null) return;

    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    if (x == null) return;

    await AppDb.instance.updatePhotos(
      workItemId: _item!.id,
      beforePath: before ? x.path : null,
      afterPath: before ? null : x.path,
    );

    if (mounted) setState(() {});
  }

  Future<void> _deletePhoto({required bool before}) async {
    if (_item == null) return;

    await AppDb.instance.updatePhotos(
      workItemId: _item!.id,
      beforePath: before ? "" : null,
      afterPath: before ? null : "",
    );

    if (mounted) setState(() {});
  }

  // ---------------- PDF + EMAIL ----------------

  Future<File> _generatePdfInvoice() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Work Item Invoice",
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Date: ${DateFormat('y-MM-dd').format(_item!.createdAt)}"),
            pw.SizedBox(height: 10),
            pw.Text("Customer: ${_item!.customerName}"),
            pw.Text("Phone: ${_item!.phone}"),
            pw.Text("Email: ${_item!.email}"),
            pw.Text("Address: ${_item!.address}"),
            pw.SizedBox(height: 12),
            pw.Text("Services:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ..._services.map(
              (s) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(s.name),
                  pw.Text("\$${s.amount.toStringAsFixed(2)}"),
                ],
              ),
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("\$${_item!.total.toStringAsFixed(2)}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/invoice_${_item!.id}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<void> _emailInvoice() async {
    if (_item == null) return;

    final emailText = _item!.email.trim();
    if (emailText.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Customer email is empty")),
      );
      return;
    }

    final pdfFile = await _generatePdfInvoice();

    final email = Email(
      body:
          "Hi ${_item!.customerName},\n\nPlease find attached your invoice.\n\nThanks,\nPoolPro CRM",
      subject: "Invoice - ${_item!.customerName}",
      recipients: [emailText],
      attachmentPaths: [pdfFile.path],
      isHTML: false,
    );

    await FlutterEmailSender.send(email);

    // BACKEND NOTE:
    // Replace later with Node.js email API call
  }

  // ---------------- SUCCESS PROMPT ----------------

  Future<void> _showCompletedPrompt() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  "Completed Work Item",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // close dialog
    }
  }

  // ---------------- COMPLETE ----------------

  Future<void> _completeWorkItem() async {
    if (_item == null) return;

    // optional email
    if (sendEmail) {
      await _emailInvoice();
    }

    // mark completed in DB
    await AppDb.instance.markCompleted(_item!.id);

    if (!mounted) return;

    // show success UI
    await _showCompletedPrompt();

    if (!mounted) return;

    // go to home -> work items -> completed tab
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
      arguments: {'tab': 'completed'},
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(title: "Invoice Preview", showBack: true),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _invoiceCard(),
                        const SizedBox(height: 14),
                        _photoEmailSection(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
          ),
        ],
      ),

      // ✅ IMPORTANT: this must call _completeWorkItem
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: GradientButton(
          text: "Complete Work Item",
          onTap: _completeWorkItem,
        ),
      ),
    );
  }

  Widget _invoiceCard() {
    final dateText = DateFormat('EEEE, MMMM d, y').format(_item!.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              "Work Item Invoice",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(dateText, style: const TextStyle(color: Colors.white70)),
          ]),
        ),
        const SizedBox(height: 14),
        Text(
          _item!.customerName,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        Text(_item!.phone),
        Text(_item!.email),
        Text(_item!.address),
        const Divider(height: 26),
        ..._services.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text("\$${s.amount.toStringAsFixed(2)}"),
              ],
            ),
          ),
        ),
        const Divider(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Total Amount",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(
              "\$${_item!.total.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _photoEmailSection() {
    final beforePath = (_item!.beforePhotoPath != null && _item!.beforePhotoPath!.isNotEmpty)
        ? _item!.beforePhotoPath
        : null;

    final afterPath = (_item!.afterPhotoPath != null && _item!.afterPhotoPath!.isNotEmpty)
        ? _item!.afterPhotoPath
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Checkbox(
            value: attachPhotos,
            onChanged: (v) => setState(() => attachPhotos = v ?? true),
          ),
          const Text("Attach Before/After Photos", style: TextStyle(fontWeight: FontWeight.w900)),
        ]),
        if (attachPhotos) ...[
          const SizedBox(height: 10),
          _photoBox(title: "Before Photo", path: beforePath, before: true),
          const SizedBox(height: 12),
          _photoBox(title: "After Photo", path: afterPath, before: false),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Checkbox(
            value: sendEmail,
            onChanged: (v) => setState(() => sendEmail = v ?? false),
          ),
          const Text("Send Email", style: TextStyle(fontWeight: FontWeight.w900)),
        ]),
      ]),
    );
  }

  Widget _photoBox({required String title, required String? path, required bool before}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.subText,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Stack(children: [
        InkWell(
          onTap: () => _pickPhoto(before: before),
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
              onTap: () => _deletePhoto(before: before),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
      ]),
    ]);
  }
}
