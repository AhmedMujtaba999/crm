import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:crm/models/models.dart';
import '../storage.dart';
import 'package:crm/services/invoice_pdf_service.dart';
import 'package:crm/services/email_service.dart';
import 'package:crm/service_of_providers/work_items_services.dart';

class InvoiceLoadResult {
  final WorkItem item;
  final List<ServiceItem> services;
  final List<String> beforePhotos;
  final List<String> afterPhotos;

  InvoiceLoadResult(
    this.item,
    this.services,
    this.beforePhotos,
    this.afterPhotos,
  );
}

class InvoiceService {
  final _picker = ImagePicker();
  final _pdfService = InvoicePdfService();
  final _emailService = EmailService();
  final WorkItemsService _workItemsService = WorkItemsService();

  // ✅ NEW: Load invoice using WorkItem you already got from API list
  Future<InvoiceLoadResult> loadFromWorkItem({
    required WorkItem item,
  }) async {
    final before = await _readManifest(item.id, true);
    final after = await _readManifest(item.id, false);

    // ✅ IMPORTANT:
    // This assumes your WorkItem already contains services OR you store them separately.
    // If your WorkItem doesn't include services, we’ll pass services from UI/provider instead.
    final services = item.services ?? <ServiceItem>[];

    return InvoiceLoadResult(item, services, before, after);
  }

  // ---------------- Photos ----------------
  Future<String?> addPhotoFromCamera(String id, bool before) async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );
    if (x == null) return null;
    return _storePickedFile(id, before, x);
  }

  Future<List<String>> addPhotosFromGallery(
    String id,
    bool before, {
    required int remaining,
  }) async {
    final picks = await _picker.pickMultiImage(imageQuality: 75);
    final selected = picks.take(remaining);

    final paths = <String>[];
    for (final x in selected) {
      paths.add(await _storePickedFile(id, before, x));
    }
    return paths;
  }

  Future<void> removePhoto(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  Future<void> persistPhotos(
    String id,
    List<String> before,
    List<String> after,
  ) async {
    await _writeManifest(id, true, before);
    await _writeManifest(id, false, after);

    // ✅ Keep local photo caching only (as you requested)
    await AppDb.instance.updatePhotos(
      workItemId: id,
      beforePath: before.isEmpty ? "" : before.first,
      afterPath: after.isEmpty ? "" : after.first,
    );
  }
Future<void> updateCustomerInfo({
  required String workItemId,
  required String customerName,
  required String phone,
  required String email,
  required String address,
}) async {
  await AppDb.instance.updateWorkItemCustomerInfo(
    workItemId: workItemId,
    customerName: customerName,
    phone: phone,
    email: email,
    address: address,
  );
}
// ---------------- COMPLETE (API) ----------------
Future<void> markCompletedApi({
  required String workItemId,
  required bool sendInvoice,
  required bool sendPictures,
}) async {
  await _workItemsService.updateTaskStatus(
    taskId: workItemId,
    status: 'COMPLETED',
    sendInvoice: sendInvoice,
    sendPictures: sendPictures,
  );
}

  // ---------------- PDF ----------------
  Future<Uint8List> buildPdf(
    WorkItem item,
    List<ServiceItem> services,
    bool includePhotos,
    List<String> before,
    List<String> after,
  ) async {
    final bytes = await _pdfService.buildPdfBytes(
      item: item,
      services: services,
      includePhotos: includePhotos,
      beforePhotoPaths: before,
      afterPhotoPaths: after,
    );
    return Uint8List.fromList(bytes);
  }

  Future<void> sharePdf(Uint8List bytes, WorkItem item) {
    return Printing.sharePdf(bytes: bytes, filename: 'invoice_${item.id}.pdf');
  }

  Future<String> savePdf(Uint8List bytes, WorkItem item) async {
    final dir = await getApplicationDocumentsDirectory();
    final invoicesDir = Directory('${dir.path}/invoices');

    if (!await invoicesDir.exists()) {
      await invoicesDir.create(recursive: true);
    }

    final file = File('${invoicesDir.path}/invoice_${item.id}.pdf');
    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }

  // ---------------- Email ----------------
  Future<void> sendEmail(
    WorkItem item,
    Uint8List pdfBytes,
    List<String> before,
    List<String> after, {
    required bool attachPhotos,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/invoice_${item.id}.pdf');

    await file.writeAsBytes(pdfBytes, flush: true);

    return _emailService.sendInvoiceEmail(
      item: item,
      pdfPath: file.path,
      attachPhotos: attachPhotos,
      beforePhotoPaths: before,
      afterPhotoPaths: after,
    );
  }

  // ---------------- Helpers ----------------
  Future<Directory> _baseDir(String id) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/work_items/$id');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> _storePickedFile(String id, bool before, XFile x) async {
    final base = await _baseDir(id);
    final dir = Directory('${base.path}/photos/${before ? "before" : "after"}');
    if (!await dir.exists()) await dir.create(recursive: true);

    final out = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await out.writeAsBytes(await x.readAsBytes(), flush: true);
    return out.path;
  }

  Future<File> _manifest(String id, bool before) async {
    final base = await _baseDir(id);
    return File('${base.path}/${before ? "before" : "after"}_photos.json');
  }

  Future<List<String>> _readManifest(String id, bool before) async {
    final f = await _manifest(id, before);
    if (!await f.exists()) return [];
    return List<String>.from(jsonDecode(await f.readAsString()));
  }

  Future<void> _writeManifest(
    String id,
    bool before,
    List<String> paths,
  ) async {
    final f = await _manifest(id, before);
    await f.writeAsString(jsonEncode(paths), flush: true);
  }
}
