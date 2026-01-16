import '../storage.dart';
import 'package:crm/models/models.dart';

import 'package:uuid/uuid.dart';


class CreateWorkItemService {
  Future<bool> customerExists({
    required String phone,
    required String email,
  }) {
    return AppDb.instance.customerExists(phone: phone, email: email);
  }

  Future<WorkItem?> findLatestByCustomer({
    required String phone,
    required String email,
  }) {
    return AppDb.instance.findLatestWorkItemByCustomer(
      phone: phone,
      email: email,
    );
  }

  Future<void> saveWorkItem(
    WorkItem item,
    List<ServiceItem> services,
  ) async {
    await AppDb.instance.insertWorkItem(item, services);
  }

  Future<void> save({
  required String customerName,
  required String phone,
  required String email,
  required String address,
  required String notes,
  required List<ServiceItem> services,
}) async {
  final id = const Uuid().v4();

  final total = services.fold(0.0, (p, e) => p + e.amount);

  final item = WorkItem(
    id: id,
    status: 'active',
    createdAt: DateTime.now(),
    customerName: customerName,
    phone: phone,
    email: email,
    address: address,
    notes: notes,
    
    total: double.parse(total.toStringAsFixed(2)),
  );

  final mappedServices = services
      .map((s) => ServiceItem(
            id: s.id,
            workItemId: id, // ✅ LINK FIX
            name: s.name,
            amount: s.amount,
          ))
      .toList();

  await AppDb.instance.insertWorkItem(item, mappedServices);
}

}
