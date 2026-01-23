import 'package:flutter/material.dart';
import 'package:crm/models/models.dart';
import 'package:crm/service_of_providers/work_items_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
class WorkItemsProvider extends ChangeNotifier {
  final _service = WorkItemsService();

  bool isLoading = false;
  List<WorkItem> _items = [];
  List<WorkItem> get items => _items;


  Future<void> load({
    required bool active,
    required DateTime date,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final empId = prefs.getString('employee_id');
      if (empId == null) throw Exception("Employee not logged in");

      _items = active
          ? await _service.getActiveWorkItems(empId: empId, date: date)
          : await _service.getCompletedWorkItems(empId: empId, date: date);
    } catch (e) {
      debugPrint("Load work items failed: $e");
      _items = [];
    }

    isLoading = false;
    notifyListeners();
  }

  void clear() {
    _items = [];
    notifyListeners();
  }

  
  Future<void> deleteItem(String id) async {
  //  await _service.delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

}