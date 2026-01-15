import 'package:flutter/material.dart';
import '../service_of_providers/task_create_service.dart';

class TaskCreateProvider extends ChangeNotifier {
  final TaskCreateService _service = TaskCreateService();

  bool saving = false;
  DateTime scheduledAt = DateTime.now();

  final services = const [
    'Select service',
    'Water Change',
    'Filter Service',
    'Pool Cleaning',
    'Chemical Treatment',
  ];

  String selectedService = 'Select service';

  void setDate(DateTime date) {
    scheduledAt = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setService(String value) {
    selectedService = value;
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

    if (selectedService == 'Select service') {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please select a service")));
      return false;
    }

    saving = true;
    notifyListeners();

    try {
      final finalTitle = title.trim().isEmpty ? selectedService : title.trim();

      await _service.createTask(
        customerName: customerName.trim(),
        phone: phone.trim(),
        email: email.trim(),
        address: address.trim(),
        title: finalTitle,
        scheduledAt: scheduledAt,
      );

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Save failed: $e")));
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
