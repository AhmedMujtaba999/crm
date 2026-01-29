import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crm/models/models.dart';
import 'package:crm/providers/task_provider.dart';
import '../service_of_providers/task_create_service.dart';
import '../service_of_providers/create_work_item_service.dart';

class TaskCreateProvider extends ChangeNotifier {
  final CreateWorkItemService _catalogService = CreateWorkItemService();
  final TaskCreateService _taskService = TaskCreateService();

  List<ServiceCatalogItem> servicesCatalog = [];
  bool isLoadingCatalog = false;

  final List<TaskServiceItem> services = [];
String? createdTaskId;

  bool saving = false;
  DateTime scheduledAt = DateTime.now();

  TaskCreateProvider() {
    _loadServiceCatalog();
  }

  double get total => services.fold(0, (sum, s) => sum + s.amount);

  void setDate(DateTime date) {
    scheduledAt = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void addService(ServiceCatalogItem service, double amount) {
    services.add(
      TaskServiceItem(
        id: service.id, // backend service_id
        taskId: '',
        name: service.name,
        amount: amount,
      ),
    );
    notifyListeners();
  }
 


  void removeService(TaskServiceItem s) {
    services.remove(s);
    notifyListeners();
  }

  Future<void> _loadServiceCatalog() async {
    isLoadingCatalog = true;
    notifyListeners();
    try {
      servicesCatalog = await _catalogService.getServiceCatalog();
    } finally {
      isLoadingCatalog = false;
      notifyListeners();
    }
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

    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one service")),
      );
      return false;
    }

    saving = true;
    notifyListeners();

    try {
      final finalTitle = title.trim().isEmpty
          ? services.map((s) => s.name).join(', ')
          : title.trim();

      // 🔥 Convert UI → API model
      final apiServices = services.map((s) {
        return ServiceItem(
          serviceid: s.id,
          name: s.name,
          amount: s.amount,
        );
      }).toList();

      // 🔥 CREATE TASK (API)
      createdTaskId = await _taskService.createTask(
        customerName: customerName,
        phone: phone,
        email: email,
        address: address,
        title: finalTitle,
        scheduledAt: scheduledAt,
        services: apiServices,
      );

      // 🔥 CREATE LOCAL TASK ITEM
      final newTask = TaskItem(
        id: createdTaskId!,
        title: finalTitle,
        customerName: customerName,
        phone: phone,
        email: email,
        address: address,
        status: "PENDING",
        scheduledAt: scheduledAt,
        services: services
            .map(
              (s) => TaskServiceItem(
                id: s.id,
                taskId: createdTaskId!,
                name: s.name,
                amount: s.amount,
              ),
            )
            .toList(),
      );

      // 🔥 PUSH TO TASKS SCREEN
      context.read<TasksProvider>().addTask(newTask);

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save failed: $e")),
      );
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
  
}

