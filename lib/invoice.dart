import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'widgets.dart';
import 'theme.dart';

import 'providers/invoice_provider.dart';
import 'pdf_preview_page.dart';
import 'providers/work_items_provider.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
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
    if (mounted) Navigator.of(context).pop();
  }

  static const int _maxPhotosPerSection = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  String? _readWorkItemId() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map && args['id'] is String) return args['id'];
    return null;
  }

  Future<void> _init() async {
    final id = _readWorkItemId();
    if (id == null) return;
    await context.read<InvoiceProvider>().load(id);
  }

  // ===================== COMPLETE =====================
  Future<void> _completeWorkItem() async {
    final p = context.read<InvoiceProvider>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Complete work item?"),
        content: Text(
          p.sendEmail
              ? "This will mark the work item as completed and send the invoice email."
              : "This will mark the work item as completed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Complete"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    /// 1️⃣ COMPLETE (NO NAVIGATION YET)
    await p.complete();

    if (!mounted) return;

    /// 2️⃣ SHOW GREEN POPUP (BLOCKING)
    await _showCompletedPrompt();

    if (!mounted) return;

    /// 3️⃣ REFRESH COMPLETED LIST
   await context.read<WorkItemsProvider>().load(active: false, date: DateTime.now());


    if (!mounted) return;

    /// 4️⃣ NOW NAVIGATE
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (_) => false,
      arguments: {'tab': 1, 'workTab': 'completed'},
    );
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    final p = context.watch<InvoiceProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          GradientHeader(
            title: p.photosEditable ? "Invoice" : "Invoice Preview",
            showBack: true,
          ),
          Expanded(
            child: p.loading
                ? const Center(child: CircularProgressIndicator())
                : p.item == null
                ? _errorState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _actionRow(p),
                        const SizedBox(height: 12),
                        _invoiceCard(p),
                        const SizedBox(height: 14),
                        _photoEmailSection(p),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: p.readOnly
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: GradientButton(
                text: p.completing ? "Completing..." : "Complete Work Item",
                onTap: p.completing ? () {} : _completeWorkItem,
              ),
            ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
          const SizedBox(height: 10),
          const Text(
            "Could not load invoice.",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Go Back"),
          ),
        ],
      ),
    );
  }

  // ===================== ACTION ROW =====================
  Widget _actionRow(InvoiceProvider p) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _actionBtn(Icons.picture_as_pdf, "Preview", () async {
            final bytes = await p.buildPdf(
              p.item!,
              p.services,
              p.attachPhotos,
              p.beforePhotos,
              p.afterPhotos,
            );

            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfPreviewPage(
                  title: "Invoice Preview",
                  fileName: "invoice.pdf",
                  pdfBytes: bytes,
                ),
              ),
            );
          }),

          _actionBtn(
            Icons.download,
            "Save",
            () => p.savePdf(), // ✅ PROVIDER CALL
          ),

          _actionBtn(
            Icons.share,
            "Share",
            () => p.sharePdf(), // ✅ PROVIDER CALL
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon), const SizedBox(height: 4), Text(label)],
        ),
      ),
    );
  }

  // ===================== INVOICE CARD =====================
  Widget _invoiceCard(InvoiceProvider p) {
    final it = p.item!;
    final createdText = DateFormat(
      'EEE, MMM d, y • h:mm a',
    ).format(it.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


// Edit/Save button row
        if (!p.readOnly)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: p.completing ? null : () {
                  if (p.isEditingCustomerInfo) {
                    p.saveCustomerInfo();
                  } else {
                    p.toggleEditCustomerInfo();
                  }
                },
                icon: Icon(
                  p.isEditingCustomerInfo ? Icons.check : Icons.edit,
                  size: 18,
                ),
                label: Text(
                  p.isEditingCustomerInfo ? "Save" : "Edit",
                ),
              ),
              if (p.isEditingCustomerInfo)
                TextButton.icon(
                  onPressed: () => p.toggleEditCustomerInfo(),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text("Cancel"),
                ),
            ],
          ),
        
        // Customer Information Fields
        if (p.isEditingCustomerInfo) ...[
          // Edit Mode - Text Fields
          TextFormField(
            controller: p.customerNameController,
            decoration: const InputDecoration(
              labelText: "Customer Name",
              border: OutlineInputBorder(),
              isDense: true,
            ),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: p.phoneController,
            decoration: const InputDecoration(
              labelText: "Phone",
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: p.emailController,
            decoration: const InputDecoration(
              labelText: "Email",
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: p.addressController,
            decoration: const InputDecoration(
              labelText: "Address",
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
        ] else ...[
          // View Mode - Text Display
          Text(
            it.customerName,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(it.phone),
          if (it.email.isNotEmpty) Text(it.email),
          if (it.address.isNotEmpty) Text(it.address),
        ],
        
        const Divider(height: 26),
        
        // Services section (unchanged)
        ...p.services.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text("\$${s.amount.toStringAsFixed(2)}"),
              ],
            ),
          ),
        ),
        const Divider(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Total Amount",
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              "\$${it.total.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
  
  





          Text(
            it.customerName,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(it.phone),
          if (it.email.isNotEmpty) Text(it.email),
          if (it.address.isNotEmpty) Text(it.address),
          const Divider(height: 26),
          ...p.services.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text("\$${s.amount.toStringAsFixed(2)}"),
                ],
              ),
            ),
          ),
          const Divider(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Amount",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                "\$${it.total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== PHOTOS + EMAIL =====================
  Widget _photoEmailSection(InvoiceProvider p) {
    final Invoicedisabled = p.readOnly || p.completing;
     final photosDisabled = p.completing || (p.readOnly && !p.photosEditable);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ✅ Attach Photos
          CheckboxListTile(
            value: p.attachPhotos,
            onChanged: photosDisabled ? null : (v) => p.toggleAttachPhotos(v ?? false),
            title: const Text("Attach Before/After Photos"),
          ),

          if (p.attachPhotos) ...[
            _photoSection(
              title: "Before Photos",
              photos: p.beforePhotos,
              disabled: photosDisabled,
              onCamera: () => p.addFromCamera(before: true),
              onGallery: () => p.addFromGallery(before: true),
              onRemove: (path) => p.removePhoto(before: true, path: path),
            ),
            const SizedBox(height: 14),
            _photoSection(
              title: "After Photos",
              photos: p.afterPhotos,
              disabled: photosDisabled,
              onCamera: () => p.addFromCamera(before: false),
              onGallery: () => p.addFromGallery(before: false),
              onRemove: (path) => p.removePhoto(before: false, path: path),
            ),
          ], 
           // send photos
            if (p.attachPhotos)
            CheckboxListTile(
              value: p.sendPhotos,
              onChanged: photosDisabled?null:(v) => p.toggleSendPhotos(v?? false),
              title: const Text("Send photos"),
            ),
          /// ✅ Send Email
          CheckboxListTile(
            value: p.sendEmail,
            onChanged: (p.item!.email.isEmpty || Invoicedisabled)
                ? null
                : (v) => p.toggleSendEmail(v ?? false),
            title: const Text("Send Email"),
          ),

          if (p.item!.email.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 4),
              child: Text(
                "No customer email on file — add an email to enable sending.",
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        
        ],
      ),
    );
  }

  Widget _photoSection({
    required String title,
    required List<String> photos,
    required bool disabled,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    required void Function(String) onRemove,
  }) {
    final limitReached = photos.length >= _maxPhotosPerSection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: disabled || limitReached ? null : onCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text("Camera"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: disabled || limitReached ? null : onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text("Gallery"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "${photos.length} / $_maxPhotosPerSection selected",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        photos.isEmpty
            ? const Text(
                "No photos added.",
                style: TextStyle(color: Colors.grey),
              )
            : Wrap(
                spacing: 10,
                runSpacing: 10,
                children: photos
                    .map(
                      (p) => _thumb(
                        p,
                        disabled: disabled,
                        onRemove: () => onRemove(p),
                      ),
                    )
                    .toList(),
              ),
      ],
    );
  }

  Widget _thumb(
    String path, {
    required bool disabled,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: 96,
            height: 96,
            fit: BoxFit.cover,
          ),
        ),
        if (!disabled)
          Positioned(
            right: 6,
            top: 6,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    );
  }
}
