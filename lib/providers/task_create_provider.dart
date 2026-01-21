import 'package:flutter/material.dart';
import '../service_of_providers/task_create_service.dart';
import 'package:crm/models/models.dart';

class TaskCreateProvider extends ChangeNotifier {
  final List<String> servicesCatalog = [
    'Water Change',
    'Filter Service',
    'Pool Cleaning',
    'Chemical Treatment',
  ];

  final List<TaskServiceItem> services = [];

  double get total => services.fold(0, (sum, s) => sum + s.amount);

  void addService(String name, double amount) {
    if (services.any((s) => s.name == name)) return; // block duplicate
    services.add(TaskServiceItem(name: name, amount: amount));
    notifyListeners();
  }

  void removeService(TaskServiceItem s) {
    services.remove(s);
    notifyListeners();
  }

  final TaskCreateService _service = TaskCreateService();

  bool saving = false;
  DateTime scheduledAt = DateTime.now();

  void setDate(DateTime date) {
    scheduledAt = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  Future<bool> submit({
    required String customerName,
    required String phone,
    required String email,
    required String address,
    required String title,
    required BuildContext context,
  }) async {
    if (saving) return false;

    //     if (selectedServices.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Please select at least one service")),
    //   );}
    //   return false;
    // }
    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one service using +"),
        ),
      );
      return false;
    }

    saving = true;
    notifyListeners();

    try {
      final finalTitle = title.trim().isEmpty
          ? services.map((s) => s.name).join(', ')
          : title.trim();

      await _service.createTask(
        customerName: customerName.trim(),
        phone: phone.trim(),
        email: email.trim(),
        address: address.trim(),
        title: finalTitle,
        scheduledAt: scheduledAt,
        services: services,
      );

      return true;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
