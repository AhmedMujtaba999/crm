import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:crm/models/models.dart';
import '../service_of_providers/invoice_service.dart';
import 'package:crm/services/invoice_pdf_service.dart';
import 'package:crm/service_of_providers/create_work_item_service.dart';
class InvoiceProvider extends ChangeNotifier {
  final InvoiceService _service = InvoiceService();
  final CreateWorkItemService _createWorkItemService = CreateWorkItemService();
  List<ServiceCatalogItem> _serviceCatalog = [];
  void toggleAttachPhotos(bool value) {
    attachPhotos = value;
    if (!attachPhotos) {
      sendPhotos = false;
    }
    notifyListeners();
  }

  void toggleSendEmail(bool value) {
    sendEmail = value;
    notifyListeners();
  }

  void toggleSendPhotos(bool value) {
    sendPhotos = value;
    notifyListeners();
  }

  // =======================
  // State
  // =======================
  bool sendPhotosOnly = false;
  void toggleSendPhotosOnly(bool value) {
    sendPhotosOnly = value;
    notifyListeners();
  }

  bool isEditingCustomerInfo = false;
  late TextEditingController customerNameController = TextEditingController();
  late TextEditingController phoneController = TextEditingController();
  late TextEditingController emailController = TextEditingController();
  late TextEditingController addressController = TextEditingController();
  WorkItem? item;
  List<ServiceItem> services = [];

  bool loading = true;
  bool completing = false;
  bool readOnly = false;

  bool sendPhotos = false;
  bool attachPhotos = true;
  bool sendEmail = false;
  bool photosEditable = false;

  List<String> beforePhotos = [];
  List<String> afterPhotos = [];

  static const int maxPhotosPerSection = 20;

  // =======================
  // Service Catalog
  // =======================
  Future<void> _loadServiceCatalog() async {
    try {
      _serviceCatalog = await _createWorkItemService.getServiceCatalog();
      debugPrint('Service Catalog loaded with ${_serviceCatalog.length} items.');
    } catch (e) {
      debugPrint('Error loading service catalog: $e');
    }
  }

  // =======================
  // Load
  // =======================
  Future<void> loadFromWorkItem({required WorkItem workItem}) async {
    loading = true;
    notifyListeners();

    try {
      await _loadServiceCatalog(); // Ensure catalog is loaded

      final result = await _service.loadFromWorkItem(item: workItem);

      item = result.item;
      // Enrich services with names from the catalog
      services = result.services.map((serviceItem) {
        debugPrint('Processing ServiceItem with ID: ${serviceItem.serviceid}');
        final catalogItem = _serviceCatalog.firstWhere(
          (catalog) => catalog.id == serviceItem.serviceid,
          orElse: () => ServiceCatalogItem(
            id: serviceItem.serviceid,
            name: 'Unknown Service',
            description: '',
          ), // Fallback
        );
        return ServiceItem(
          serviceid: serviceItem.serviceid,
          name: catalogItem.name, // Use the name from the catalog
          amount: serviceItem.amount,
        );
      }).toList();

      beforePhotos = List.from(result.beforePhotos);
      afterPhotos = List.from(result.afterPhotos);

      // controllers already exist → just set text
      customerNameController.text = item?.customerName ?? '';
      phoneController.text = item?.phone ?? '';
      emailController.text = item?.email ?? '';
      addressController.text = item?.address ?? '';

      photosEditable = true;
      readOnly = item?.status.toLowerCase() == 'completed';
    } catch (e) {
      debugPrint('Error loading invoice: $e');
      item = null;
      services.clear();
    } finally {
      loading = false;
      notifyListeners();
    }
  }


  // =======================
  // Helpers
  // =======================
  bool limitReached(bool before) {
    return (before ? beforePhotos.length : afterPhotos.length) >=
        maxPhotosPerSection;
  }

  // =======================
  // Photos – Camera
  // =======================
  Future<void> addFromCamera({required bool before}) async {
    if (item == null || !photosEditable || completing) return;
    if (limitReached(before)) return;

    final path = await _service.addPhotoFromCamera(item!.id.toString(), before);
    if (path == null) return;

    if (before) {
      beforePhotos.add(path);
    } else {
      afterPhotos.add(path);
    }

    await _service.persistPhotos(
      item!.id.toString(),
      beforePhotos,
      afterPhotos,
    );

    notifyListeners();
  }

  // =======================
  // Photos – Gallery
  // =======================
  Future<void> addFromGallery({required bool before}) async {
    if (item == null || !photosEditable || completing) return;

    final remaining =
        maxPhotosPerSection -
        (before ? beforePhotos.length : afterPhotos.length);
    if (remaining <= 0) return;

    final paths = await _service.addPhotosFromGallery(
      item!.id.toString(),
      before,
      remaining: remaining,
    );

    if (paths.isEmpty) return;

    if (before) {
      beforePhotos.addAll(paths);
    } else {
      afterPhotos.addAll(paths);
    }

    await _service.persistPhotos(
      item!.id.toString(),
      beforePhotos,
      afterPhotos,
    );

    notifyListeners();
  }

  // =======================
  // Photos – Remove
  // =======================
  Future<void> removePhoto({required bool before, required String path}) async {
    if (item == null || !photosEditable || completing) return;

    await _service.removePhoto(path);

    if (before) {
      beforePhotos.remove(path);
    } else {
      afterPhotos.remove(path);
    }

    await _service.persistPhotos(
      item!.id.toString(),
      beforePhotos,
      afterPhotos,
    );

    notifyListeners();
  }

  // =======================
  // PDF
  // =======================
  Future<Uint8List> buildPdf(
    WorkItem item,
    List<ServiceItem> services,
    bool attachPhotos,
    List<String> beforePhotos,
    List<String> afterPhotos,
  ) async {
    return await _service.buildPdf(
      item,
      services,
      attachPhotos,
      beforePhotos,
      afterPhotos,
    );
  }

  Future<void> sharePdf() async {
    if (item == null) return;

    final bytes = await buildPdf(
      item!,
      services,
      attachPhotos,
      beforePhotos,
      afterPhotos,
    );

    await _service.sharePdf(bytes, item!);
  }

  Future<void> savePdf() async {
    if (item == null) return;

    final bytes = await buildPdf(
      item!,
      services,
      attachPhotos,
      beforePhotos,
      afterPhotos,
    );

    final path = await _service.savePdf(bytes, item!);

    print("Saved at: $path");

    try {
      await OpenFilex.open(path);
    } catch (e) {
      debugPrint("Open failed: $e");
    }
  }

  // =======================
  // Complete
  // =======================
  Future<void> complete() async {
    if (item == null || completing) return;

    completing = true;
    notifyListeners();

    try {
      final bytes = await buildPdf(
        item!,
        services,
        attachPhotos,
        beforePhotos,
        afterPhotos,
      );

      // Save PDF
      final pdfPath = await _service.savePdf(bytes, item!);

      // Optional email

      if (sendEmail) {
        try {
          await _service.sendEmail(
            item!,
            bytes,
            beforePhotos,
            afterPhotos,
            attachPhotos: sendPhotos,
          );
        } catch (e) {
          debugPrint("⚠️ Email not available: $e");
          // DO NOT THROW — allow completion to continue
        }
      }

      // Mark completed in DB
      //final completedAt = DateTime.now();
     await _service.markCompletedApi(
  workItemId: item!.id,
  sendInvoice: sendEmail,
  sendPictures: sendPhotos,
);


      // Update local state ONLY
      item = item!.copyWith(
        status: 'COMPLETED',
        completedAt: DateTime.now(),
        attachPhotos: attachPhotos,
        sendPhotosOnly: sendPhotosOnly,
        sendEmail: sendEmail,
        pdfPath: pdfPath,
      );
      readOnly = true;
      photosEditable = true;
    } finally {
      completing = false;
      notifyListeners();
    }
  }

  void toggleEditCustomerInfo() {
    if (item == null || readOnly) return;
    isEditingCustomerInfo = !isEditingCustomerInfo;

    if (!isEditingCustomerInfo) {
      // Reset controllers to original values when canceling
      customerNameController.text = item?.customerName ?? '';
      phoneController.text = item?.phone ?? '';
      emailController.text = item?.email ?? '';
      addressController.text = item?.address ?? '';
    }

    notifyListeners();
  }

  Future<void> saveCustomerInfo() async {
    if (item == null || !isEditingCustomerInfo) return;

    await _service.updateCustomerInfo(
      workItemId: item!.id.toString(),
      customerName: customerNameController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      address: addressController.text.trim(),
    );

    // Update local item
    item = item!.copyWith(
      customerName: customerNameController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      address: addressController.text.trim(),
    );

    // Update sendEmail based on email field
    sendEmail = emailController.text.trim().isNotEmpty && sendEmail;

    isEditingCustomerInfo = false;
    notifyListeners();
  }

  @override
  void dispose() {
    customerNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
