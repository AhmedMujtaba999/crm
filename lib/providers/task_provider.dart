import 'package:flutter/material.dart';
import 'package:crm/models/models.dart';
import 'package:crm/service_of_providers/task_service.dart';

class TasksProvider extends ChangeNotifier {
  final TasksService _service = TasksService();

  DateTime? filterDate;
  bool loading = false;

  List<TaskItem> _tasks = [];
  List<TaskItem> get tasks => _tasks;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> load() async {
    loading = true;
    notifyListeners();
    _tasks = await _service.listTasks(forDate: filterDate);
    loading = false;
    notifyListeners();
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

 void addTask(TaskItem task) {
  _tasks.insert(0, task); // show on top
  notifyListeners();
}
}