import 'package:flutter/material.dart';
import 'package:crm/models/models.dart';
import 'package:crm/service_of_providers/task_service.dart';
import 'package:crm/service_of_providers/create_work_item_service.dart';


class TasksProvider extends ChangeNotifier {
  final TasksService _service = TasksService();
  final CreateWorkItemService _catalogService = CreateWorkItemService();

  List<ServiceCatalogItem> servicesCatalog = [];
  bool isLoadingCatalog = false;
TasksProvider(){
    _loadServiceCatalog();
}
  DateTime? filterDate;
  bool loading = false;
  List<TaskItem> _tasks = [];
  List<TaskItem> get tasks => _tasks;
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
 Future<void> load() async {
  loading = true;
  notifyListeners();

  try {
    final tasks = await TasksService().listTasks(
      forDate: filterDate ?? DateTime.now(),
      status: "PENDING",
    );
    _tasks = tasks;
  } catch (e, st) {
    debugPrint("❌ load() error: $e");
    debugPrint("$st");
    _tasks = []; // optional
  } finally {
    loading = false;
    notifyListeners();
  }
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

  Future<void> pickDate(DateTime d) async {
    filterDate = _dateOnly(d);
    await load();
  }

  Future<void> clearFilter() async {
    filterDate = null;
    await load();
  }

  Future<void> delete(TaskItem task) async {
    await _service.deleteTask(task.id);
    _tasks.removeWhere((t) => t.id == task.id);
    notifyListeners();
  }

//  void addTask(TaskItem task) {
//   _tasks.insert(0, task); // show on top
//   notifyListeners();
// }
String serviceNameFromCatalog(String serviceId, {String? fallbackName}) {
  final n = (fallbackName ?? '').trim();
  if (n.isNotEmpty) return n;

  final match = servicesCatalog.where((c) => c.id == serviceId).toList();
  return match.isNotEmpty ? match.first.name : "Unknown service";
}

}