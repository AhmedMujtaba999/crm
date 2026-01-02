import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import 'models.dart';
import 'storage.dart';
import 'widgets.dart';
import 'theme.dart';

import 'pdf_preview_page.dart';
import 'services/invoice_pdf_service.dart';
import 'services/email_service.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final _pdfService = InvoicePdfService();
  final _emailService = EmailService();
  final _picker = ImagePicker();

  bool attachPhotos = true;
  bool sendEmail = false;

  WorkItem? _item;
  List<ServiceItem> _services = [];
  bool _loading = true;
  bool _completing = false;

  bool _readOnly = false;

  // ✅ Multi before/after photos (1..20 each)
  static const int _maxPhotosPerSection = 20;
  List<String> _beforePhotos = [];
  List<String> _afterPhotos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String? _readWorkItemId() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map && args['id'] is String) {
      final id = (args['id'] as String).trim();
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  Future<void> _init() async {
    final id = _readWorkItemId();
    if (id == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack("Missing Work Item ID.");
      return;
    }

    try {
      final item = await AppDb.instance.getWorkItem(id);
      final services = await AppDb.instance.listServices(id);

      if (!mounted) return;

      setState(() {
        _item = item;
        _services = services;
        _loading = false;

        _readOnly = (item != null && item.status == 'completed');
        sendEmail = (item == null) ? false : item.email.trim().isNotEmpty;
      });

      await _loadPhotoLists();
      await _syncDbRepresentativePhotos(); // keep DB fields updated (first photo)
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack("Failed to load invoice: $e");
    }
  }

  // -------------------- Storage for photo lists --------------------
  Future<Directory> _workDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/work_items/${_item!.id}');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _photoDir({required bool before}) async {
    final base = await _workDir();
    final dir = Directory('${base.path}/photos/${before ? "before" : "after"}');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _manifestFile({required bool before}) async {
    final base = await _workDir();
    return File('${base.path}/${before ? "before_photos" : "after_photos"}.json');
  }

  Future<void> _loadPhotoLists() async {
    if (_item == null) return;

    final before = await _readManifest(before: true);
    final after = await _readManifest(before: false);

    // ✅ Backward compatibility: if manifest empty but DB has single path, seed list
    final legacyBefore = (_item!.beforePhotoPath ?? '').trim();
    final legacyAfter = (_item!.afterPhotoPath ?? '').trim();

    final seededBefore = List<String>.from(before);
    final seededAfter = List<String>.from(after);

    if (seededBefore.isEmpty && legacyBefore.isNotEmpty && File(legacyBefore).existsSync()) {
      seededBefore.add(legacyBefore);
      await _writeManifest(before: true, paths: seededBefore);
    }
    if (seededAfter.isEmpty && legacyAfter.isNotEmpty && File(legacyAfter).existsSync()) {
      seededAfter.add(legacyAfter);
      await _writeManifest(before: false, paths: seededAfter);
    }

    if (!mounted) return;
    setState(() {
      _beforePhotos = seededBefore.take(_maxPhotosPerSection).toList();
      _afterPhotos = seededAfter.take(_maxPhotosPerSection).toList();
    });
  }

  Future<List<String>> _readManifest({required bool before}) async {
    try {
      final f = await _manifestFile(before: before);
      if (!await f.exists()) return [];
      final raw = await f.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final valid = <String>[];
      for (final v in decoded) {
        if (v is String && v.trim().isNotEmpty) {
          final file = File(v);
          if (await file.exists()) valid.add(v);
        }
      }
      return valid.take(_maxPhotosPerSection).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeManifest({required bool before, required List<String> paths}) async {
    try {
      final f = await _manifestFile(before: before);
      await f.writeAsString(jsonEncode(paths.take(_maxPhotosPerSection).toList()), flush: true);
    } catch (e) {
      _snack("Saving photo list failed: $e");
    }
  }

  Future<String> _storePickedFile({required bool before, required XFile x}) async {
    final dir = await _photoDir(before: before);

    // keep extension if possible
    String ext = ".jpg";
    final name = x.name;
    final dot = name.lastIndexOf('.');
    if (dot != -1 && dot < name.length - 1) {
      ext = name.substring(dot);
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final out = File('${dir.path}/${before ? "before" : "after"}_$ts$ext');

    final bytes = await x.readAsBytes();
    await out.writeAsBytes(bytes, flush: true);

    return out.path;
  }

  Future<void> _syncDbRepresentativePhotos() async {
    if (_item == null) return;

    // keep DB fields as first image (so other pages still show 1 image)
    final repBefore = _beforePhotos.isEmpty ? "" : _beforePhotos.first;
    final repAfter = _afterPhotos.isEmpty ? "" : _afterPhotos.first;

    try {
      await AppDb.instance.updatePhotos(
        workItemId: _item!.id,
        beforePath: repBefore,
        afterPath: repAfter,
      );

      final fresh = await AppDb.instance.getWorkItem(_item!.id);
      if (!mounted) return;
      setState(() => _item = fresh);
    } catch (_) {
      // ignore if DB update fails; manifests still work
    }
  }

  // -------------------- Add / Remove Photos --------------------
  bool _limitReached(bool before) =>
      (before ? _beforePhotos.length : _afterPhotos.length) >= _maxPhotosPerSection;

  Future<void> _addFromCamera({required bool before}) async {
    if (_item == null) return;
    if (_readOnly || _completing) return;

    if (_limitReached(before)) {
      _snack("Max $_maxPhotosPerSection ${before ? "before" : "after"} photos reached.");
      return;
    }

    try {
      final x = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
      if (x == null) return;

      final path = await _storePickedFile(before: before, x: x);

      setState(() {
        if (before) {
          _beforePhotos.add(path);
        } else {
          _afterPhotos.add(path);
        }
      });

      await _writeManifest(before: before, paths: before ? _beforePhotos : _afterPhotos);
      await _syncDbRepresentativePhotos();
    } catch (e) {
      _snack("Camera add failed: $e");
    }
  }

  Future<void> _addFromGallery({required bool before}) async {
    if (_item == null) return;
    if (_readOnly || _completing) return;

    if (_limitReached(before)) {
      _snack("Max $_maxPhotosPerSection ${before ? "before" : "after"} photos reached.");
      return;
    }

    try {
      final picks = await _picker.pickMultiImage(imageQuality: 75);
      if (picks.isEmpty) return;

      final list = before ? _beforePhotos : _afterPhotos;
      final remaining = _maxPhotosPerSection - list.length;
      final toAdd = picks.take(remaining).toList();

      final newPaths = <String>[];
      for (final x in toAdd) {
        final p = await _storePickedFile(before: before, x: x);
        newPaths.add(p);
      }

      setState(() {
        if (before) {
          _beforePhotos.addAll(newPaths);
        } else {
          _afterPhotos.addAll(newPaths);
        }
      });

      await _writeManifest(before: before, paths: before ? _beforePhotos : _afterPhotos);
      await _syncDbRepresentativePhotos();

      if (picks.length > remaining) {
        _snack("Added $remaining photo(s). Max $_maxPhotosPerSection reached.");
      }
    } catch (e) {
      _snack("Gallery add failed: $e");
    }
  }

  Future<void> _removePhoto({required bool before, required String path}) async {
    if (_item == null) return;
    if (_readOnly || _completing) return;

    try {
      final f = File(path);
      if (await f.exists()) await f.delete();

      setState(() {
        if (before) {
          _beforePhotos.remove(path);
        } else {
          _afterPhotos.remove(path);
        }
      });

      await _writeManifest(before: before, paths: before ? _beforePhotos : _afterPhotos);
      await _syncDbRepresentativePhotos();
    } catch (e) {
      _snack("Remove failed: $e");
    }
  }

  // -------------------- PDF --------------------
  String _pdfFileName() {
    final item = _item!;
    final shortId = item.id.length >= 6 ? item.id.substring(0, 6).toUpperCase() : item.id.toUpperCase();
    final d = DateFormat('yyyyMMdd').format(item.createdAt);
    return 'invoice_${d}_${shortId}.pdf';
  }

  Future<File> _savePdfToAppFiles(Uint8List bytes) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/work_items/${_item!.id}/invoices');
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File('${dir.path}/${_pdfFileName()}');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Uint8List> _buildPdfBytes() async {
    // ✅ new signature includes beforePhotoPaths/afterPhotoPaths
    try {
      final dynamic svc = _pdfService;
      final bytesList = await svc.buildPdfBytes(
        item: _item!,
        services: _services,
        includePhotos: attachPhotos,
        beforePhotoPaths: _beforePhotos,
        afterPhotoPaths: _afterPhotos,
      );
      return Uint8List.fromList(List<int>.from(bytesList));
    } catch (_) {
      // fallback if you didn't replace invoice_pdf_service.dart yet
      final bytesList = await _pdfService.buildPdfBytes(
        item: _item!,
        services: _services,
        includePhotos: attachPhotos,
      );
      return Uint8List.fromList(bytesList);
    }
  }

  Future<void> _previewPdf() async {
    if (_item == null) return;

    try {
      final bytes = await _buildPdfBytes();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewPage(
            title: "Invoice Preview",
            fileName: _pdfFileName(),
            pdfBytes: bytes,
          ),
        ),
      );
    } catch (e) {
      _snack("PDF preview failed: $e");
    }
  }

  Future<void> _sharePdf() async {
    if (_item == null) return;

    try {
      final bytes = await _buildPdfBytes();
      await Printing.sharePdf(bytes: bytes, filename: _pdfFileName());
    } catch (e) {
      _snack("Share failed: $e");
    }
  }

  Future<void> _savePdf() async {
    if (_item == null) return;

    try {
      final bytes = await _buildPdfBytes();
      final file = await _savePdfToAppFiles(bytes);
      _snack("Saved: ${file.path}");
    } catch (e) {
      _snack("Save failed: $e");
    }
  }

  // -------------------- Email --------------------
  Future<void> _sendEmailWithInvoice() async {
    if (_item == null) return;

    final bytes = await _buildPdfBytes();
    final pdfFile = await _savePdfToAppFiles(bytes);

    // ✅ new signature includes beforePhotoPaths/afterPhotoPaths
    try {
      final dynamic es = _emailService;
      await es.sendInvoiceEmail(
        item: _item!,
        pdfPath: pdfFile.path,
        attachPhotos: attachPhotos,
        beforePhotoPaths: _beforePhotos,
        afterPhotoPaths: _afterPhotos,
      );
    } catch (_) {
      await _emailService.sendInvoiceEmail(
        item: _item!,
        pdfPath: pdfFile.path,
        attachPhotos: attachPhotos,
      );
    }
  }

  // -------------------- Complete --------------------
  Future<bool> _confirmComplete() async {
    if (!mounted) return false;

    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Complete work item?"),
        content: Text(
          sendEmail
              ? "This will mark the work item as completed and open your email app to send the invoice."
              : "This will mark the work item as completed.",
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
              const SizedBox(width: 12),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Complete")),
            ],
          ),
        ],
      ),
    );

    return res ?? false;
  }

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
                decoration: BoxDecoration(color: Colors.green.shade600, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text("Completed Work Item", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _completeWorkItem() async {
    if (_item == null || _completing) return;
    if (_readOnly) return;

    final ok = await _confirmComplete();
    if (!ok) return;

    setState(() => _completing = true);

    try {
      if (sendEmail) {
        try {
          await _sendEmailWithInvoice();
        } catch (e) {
          _snack("Email failed: $e (Work item will still be completed)");
        }
      }

      await AppDb.instance.markCompleted(_item!.id);

      if (!mounted) return;
      await _showCompletedPrompt();

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
        arguments: {'tab': 1, 'workTab': 'completed'},
      );
    } catch (e) {
      _snack("Complete failed: $e");
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          GradientHeader(title: _readOnly ? "Invoice" : "Invoice Preview", showBack: true),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_item == null)
                    ? _errorState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _actionRow(),
                            const SizedBox(height: 12),
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
      bottomNavigationBar: _readOnly
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: GradientButton(
                text: _completing ? "Completing..." : "Complete Work Item",
                onTap: _completing ? () {} : _completeWorkItem,
              ),
            ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 10),
            const Text("Could not load invoice.", style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text("Go Back")),
          ],
        ),
      ),
    );
  }

  Widget _actionRow() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: (_item == null || _completing) ? null : _previewPdf,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [Icon(Icons.picture_as_pdf), SizedBox(height: 4), Text("Preview")],
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: (_item == null || _completing) ? null : _sharePdf,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [Icon(Icons.share), SizedBox(height: 4), Text("Share")],
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: (_item == null || _completing) ? null : _savePdf,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [Icon(Icons.download), SizedBox(height: 4), Text("Save")],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invoiceCard() {
    final createdText = DateFormat('EEE, MMM d, y • h:mm a').format(_item!.createdAt);
    final completedText = (_item!.completedAt == null)
        ? null
        : DateFormat('EEE, MMM d, y • h:mm a').format(_item!.completedAt!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primary2]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_readOnly ? "Invoice" : "Work Item Invoice",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text("Activated: $createdText", style: const TextStyle(color: Colors.white70)),
            if (completedText != null) ...[
              const SizedBox(height: 2),
              Text("Completed: $completedText", style: const TextStyle(color: Colors.white70)),
            ],
          ]),
        ),
        const SizedBox(height: 14),
        const Text("Customer Details", style: TextStyle(color: AppColors.subText, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(_item!.customerName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 4),
        Text(_item!.phone),
        if (_item!.email.trim().isNotEmpty) Text(_item!.email),
        if (_item!.address.trim().isNotEmpty) Text(_item!.address),
        const Divider(height: 26),
        const Text("Services", style: TextStyle(color: AppColors.subText, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (_services.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text("No services added.", style: TextStyle(color: Colors.grey)),
          )
        else
          ..._services.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800))),
                    const SizedBox(width: 12),
                    Text("\$${s.amount.toStringAsFixed(2)}"),
                  ],
                ),
              )),
        const Divider(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Total Amount", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(
              "\$${_item!.total.toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _photoEmailSection() {
    final disabled = _completing || _readOnly;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Checkbox(
              value: attachPhotos,
              onChanged: _completing ? null : (v) => setState(() => attachPhotos = v ?? true),
            ),
            const Expanded(
              child: Text("Attach Before/After Photos", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),

        if (attachPhotos) ...[
          const SizedBox(height: 10),

          _photoMultiSection(
            title: "Before Photos",
            photos: _beforePhotos,
            disabled: disabled,
            onAddCamera: () => _addFromCamera(before: true),
            onAddGallery: () => _addFromGallery(before: true),
            onRemove: (p) => _removePhoto(before: true, path: p),
          ),

          const SizedBox(height: 14),

          _photoMultiSection(
            title: "After Photos",
            photos: _afterPhotos,
            disabled: disabled,
            onAddCamera: () => _addFromCamera(before: false),
            onAddGallery: () => _addFromGallery(before: false),
            onRemove: (p) => _removePhoto(before: false, path: p),
          ),
        ],

        const SizedBox(height: 10),
        Row(
          children: [
            Checkbox(
              value: sendEmail,
              onChanged: _completing || _item!.email.trim().isEmpty ? null : (v) => setState(() => sendEmail = v ?? false),
            ),
            const Expanded(child: Text("Send Email", style: TextStyle(fontWeight: FontWeight.w900))),
          ],
        ),
        if (_item!.email.trim().isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              "No customer email on file — add an email to enable sending.",
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
      ]),
    );
  }

  Widget _photoMultiSection({
    required String title,
    required List<String> photos,
    required bool disabled,
    required VoidCallback onAddCamera,
    required VoidCallback onAddGallery,
    required void Function(String path) onRemove,
  }) {
    final limitReached = photos.length >= _maxPhotosPerSection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.subText, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: disabled || limitReached ? null : onAddCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text("Camera"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: disabled || limitReached ? null : onAddGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text("Gallery"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "${photos.length} / $_maxPhotosPerSection selected",
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 10),
        photos.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text("No photos added.", style: TextStyle(color: Colors.grey)),
              )
            : Wrap(
                spacing: 10,
                runSpacing: 10,
                children: photos.map((p) => _thumb(p, disabled: disabled, onRemove: () => onRemove(p))).toList(),
              ),
      ],
    );
  }

  Widget _thumb(String path, {required bool disabled, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(path), width: 96, height: 96, fit: BoxFit.cover),
        ),
        if (!disabled)
          Positioned(
            right: 6,
            top: 6,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
      ],
    );
  }
}
