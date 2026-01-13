import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import 'package:crm/service_of_providers/create_work_item_service.dart';

class CreateWorkItemProvider extends ChangeNotifier {
  final _service = CreateWorkItemService();

  String? confirmedCreateForPhone;
  bool isSaving = false;

  final List<ServiceItem> services = [];

  double get total =>
      services.fold(0.0, (sum, s) => sum + s.amount);

  // ---------------- Services ----------------

  void addService(String name, double amount) {
    if (services.any((s) => s.name == name)) return;

    services.add(ServiceItem(
      id: const Uuid().v4(),
      workItemId: 'temp',
      name: name,
      amount: amount,
    ));
    notifyListeners();
  }

  void removeService(ServiceItem s) {
    services.remove(s);
    notifyListeners();
  }

  void resetConfirmedCreate() {
    confirmedCreateForPhone = null;
  }

  // ---------------- Customer Checks ----------------

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

  // ---------------- Save Work Item ----------------

  Future<void> save({
    required String customerName,
    required String phone,
    required String email,
    required String address,
    required String notes,
  }) async {
    if (services.isEmpty) {
      throw Exception("No services added");
    }

    isSaving = true;
    notifyListeners();

    final id = const Uuid().v4();

    final item = WorkItem(
      id: id,
      status: 'active',
      createdAt: DateTime.now(),
      customerName: customerName,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
      total: total,
    );

    final mappedServices = services
        .map((s) => ServiceItem(
              id: s.id,
              workItemId: id,
              name: s.name,
              amount: s.amount,
            ))
        .toList();

    await _service.saveWorkItem(item, mappedServices);

    services.clear(); // reset for next create
    confirmedCreateForPhone = null;

    isSaving = false;
    notifyListeners();
  }
}
