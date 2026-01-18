import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:crm/models/models.dart';
import '../service_of_providers/invoice_service.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceService _service = InvoiceService();
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
 void toggleSendPhotos(bool value){
  sendPhotos= value;
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
  late TextEditingController customerNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;

  WorkItem? item;
  List<ServiceItem> services = [];

  bool loading = true;
  bool completing = false;
  bool readOnly = false;
  
  bool sendPhotos =false;
  bool attachPhotos = true;
  bool sendEmail = false;
  bool photosEditable= false;

  List<String> beforePhotos = [];
  List<String> afterPhotos = [];
  


  static const int maxPhotosPerSection = 20;
  

  // =======================
  // Load
  // =======================
  Future<void> load(String workItemId) async {
    loading = true;
    notifyListeners();

    final result = await _service.loadInvoice(workItemId);

    item = result.item;
    services = result.services;
    beforePhotos = List.from(result.beforePhotos);
    afterPhotos = List.from(result.afterPhotos);

    // Initialize controllers when item loads
    customerNameController = TextEditingController(text: item?.customerName ?? '');
    phoneController = TextEditingController(text: item?.phone ?? '');
    emailController = TextEditingController(text: item?.email ?? '');
    addressController = TextEditingController(text: item?.address ?? '');


    readOnly = item?.status == 'completed';
    photosEditable = true;
    
     

    attachPhotos = item?.attachPhotos ?? true;
    //sendPhotosOnly = item?.sendPhotosOnly ?? false;
    sendEmail = item?.email.trim().isNotEmpty ?? false;
    
    if(!attachPhotos) sendPhotos =false;

    loading = false;
    notifyListeners();
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
    if (item== null || !photosEditable || completing) return;

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
     final pdfPath= await _service.savePdf(bytes, item!);

      // Optional email

      if (sendEmail) {
        try {
          await _service.sendEmail(item!, bytes,beforePhotos, afterPhotos, attachPhotos:sendPhotos,);
        } catch (e) {
          debugPrint("⚠️ Email not available: $e");
          // DO NOT THROW — allow completion to continue
        }
      }

      // Mark completed in DB
      //final completedAt = DateTime.now();
      await _service.markCompleted(item!.id.toString());

      // Update local state ONLY
      item = item!.copyWith(
        status: 'completed',
       completedAt: DateTime.now(),
       attachPhotos: attachPhotos,
       sendPhotosOnly: sendPhotosOnly,
       sendEmail: sendEmail,
       pdfPath: pdfPath,
      );
       readOnly= true;
      photosEditable = true;
    } finally {
      completing = false;
      notifyListeners();
    }
  }
  void toggleEditCustomerInfo(){
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
  Future<void> saveCustomerInfo() async{
     if (item == null || !isEditingCustomerInfo) return;

    await _service.updateCustomerInfo(
      workItemId: item!.id.toString(),
      customerName: customerNameController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      address: addressController.text.trim(),);

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
