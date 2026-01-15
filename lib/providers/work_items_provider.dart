import 'package:flutter/material.dart';
import 'package:crm/models/models.dart';
import 'package:crm/service_of_providers/work_items_services.dart';


class WorkItemsProvider extends ChangeNotifier {
  final _service = WorkItemsService();

  bool isLoading = false;
  List<WorkItem> _items = [];

  List<WorkItem> get items => _items;

  Future<void> load({
    required bool active,
    required bool byDate,
    required DateTime selectedDate,
  }) async {
    isLoading = true;
    notifyListeners();

    final status = active ? 'active' : 'completed';
    final list = await _service.getByStatus(status);

    // Sorting
    list.sort((a, b) {
      final ad = active ? a.createdAt : (a.completedAt ?? a.createdAt);
      final bd = active ? b.createdAt : (b.completedAt ?? b.createdAt);
      return bd.compareTo(ad);
    });

    // Filtering (completed → by date)
    if (!active && byDate) {
      _items = list.where((it) {
        final dt = it.completedAt;
        if (dt == null) return false;
        return dt.year == selectedDate.year &&
            dt.month == selectedDate.month &&
            dt.day == selectedDate.day;
      }).toList();
    } else {
      _items = list;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    await _service.delete(id);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
