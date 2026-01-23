import 'package:flutter/material.dart';
import 'package:crm/models/models.dart';
import 'package:crm/service_of_providers/create_work_item_service.dart';

class CreateWorkItemProvider extends ChangeNotifier {
  final _service = CreateWorkItemService();

  // ---------------- SERVICE CATALOG (API) ----------------

  List<ServiceCatalogItem> _serviceCatalog = [];
  List<ServiceCatalogItem> get serviceCatalog => _serviceCatalog;

  bool isCatalogLoading = false;

  Future<void> loadServiceCatalog() async {
    try {
      isCatalogLoading = true;
      notifyListeners();

      _serviceCatalog = await _service.getServiceCatalog();
    } catch (e) {
      debugPrint('Service catalog load failed: $e');
    } finally {
      isCatalogLoading = false;
      notifyListeners();
    }
  }

  // ---------------- SELECTED SERVICES ----------------

  final List<ServiceItem> services = [];

  double get total =>
      services.fold(0.0, (sum, s) => sum + s.amount);

  void addService(ServiceCatalogItem catalogItem, double amount) {
    services.add(
      ServiceItem(
        serviceid: catalogItem.id, // ✅ REAL FK
        name: catalogItem.name,
        amount: amount,
      ),
    );
    notifyListeners();
  }

  void removeService(ServiceItem s) {
    services.remove(s);
    notifyListeners();
  }

  // ---------------- CUSTOMER FLOW ----------------

  String? confirmedCreateForPhone;
  bool isSaving = false;

  void resetConfirmedCreate() {
    confirmedCreateForPhone = null;
  }

  Future<bool> customerExists({
    required String phone,
    required String email,
  }) {
    return _service.customerExists(phone: phone, email: email);
  }

  Future<WorkItem?> findLatestByCustomer({
    required String phone,
    required String email,
  }) {
    return _service.findLatestByCustomer(phone: phone, email: email);
  }

  // ---------------- SAVE WORK ITEM ----------------

  Future<WorkItemCreateResponse> save({
    required String customerName,
    required String phone,
    required String email,
    required String address,
    required String notes,
  }) async {
    if (services.isEmpty) {
      throw Exception("Add at least one service");
    }

    isSaving = true;
    notifyListeners();

    try {
      final response = await _service.save(
        customerName: customerName,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
        services: services,
      );

      services.clear();
      confirmedCreateForPhone = null;

      return response;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
