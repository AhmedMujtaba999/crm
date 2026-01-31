import 'package:flutter/material.dart';
import 'package:crm/models/models.dart';
import 'package:crm/service_of_providers/create_work_item_service.dart';

class CreateWorkItemProvider extends ChangeNotifier {
  final _service = CreateWorkItemService();// instance of service (API calls)
  
  // ---------------- SERVICE CATALOG (API) ----------------

  List<ServiceCatalogItem> _serviceCatalog = []; //stores services from backedn 
  List<ServiceCatalogItem> get serviceCatalog => _serviceCatalog;

  bool isCatalogLoading = false; //loading indicator for catalog

  Future<void> loadServiceCatalog() async {
    try {
      isCatalogLoading = true;
      notifyListeners();
      _serviceCatalog = await _service.getServiceCatalog(); // stores the result we got from API
    } catch (e) {
      // UI wont show error here, just debug prints, we will add that later
      debugPrint('Service catalog load failed: $e');
    } finally {
      isCatalogLoading = false;
      notifyListeners();
    }
  }

  // ---------------- SELECTED SERVICES ----------------

  final List<ServiceItem> services = [];// current work items selected in UI
  double get total =>
      services.fold(0.0, (sum, s) => sum + s.amount);// total amount of selected services
// user picks a catalog service and enters amount
// provider converts that catalog item to a service item and adds to list
// stores that in services 
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
  }) async {// validatION : no services then stop
    if (services.isEmpty) {
      throw Exception("Add at least one service");
    }
     // turn on saving ui state
    isSaving = true;
    notifyListeners();
   // call backend to save work item
   // this is where the actual API call happens
    try {
      final response = await _service.save(
        customerName: customerName,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
        services: services,
      );
      // clear local state after successful save
      services.clear();
      confirmedCreateForPhone = null;
      return response;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
  // inside CreateWorkItemProvider

void clearDraft() {
  services.clear();
  confirmedCreateForPhone = null;
  notifyListeners();
}

/// Prefill provider selected services from a TaskItem coming from Tasks screen.
/// Works even if catalog isn't loaded, but uses catalog to "normalize" ids/names when possible.
void prefillFromTask(TaskItem task) {
  services.clear();

  for (final s in task.services) {
    // task.services is probably List<TaskServiceItem>
    final taskServiceId = (s.id).toString();
    final taskServiceName = (s.name).toString();

    // try to match catalog by id OR by name
    ServiceCatalogItem? match;
    for (final c in _serviceCatalog) {
      final sameId = c.id.toString() == taskServiceId;
      final sameName =
          c.name.trim().toLowerCase() == taskServiceName.trim().toLowerCase();
      if (sameId || sameName) {
        match = c;
        break;
      }
    }

    services.add(
      ServiceItem(
        serviceid: (match?.id ?? taskServiceId).toString(),
        name: match?.name ?? taskServiceName,
        amount: s.amount,
      ),
    );
  }

  notifyListeners();
}

}
