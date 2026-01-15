import 'package:flutter/material.dart';
import '../service_of_providers/home_shell_service.dart';

class HomeShellProvider extends ChangeNotifier {
  final HomeShellService _service = HomeShellService();

  int index = 0;
  String? workTab;

  int pendingTasksCount = 0;
  int activeWorkItemsCount = 0;

  bool loading = true;

  // ================= INIT =================
  void init({int initialTab = 0, String? initialWorkTab}) {
    index = initialTab;
    workTab = initialWorkTab;
    loadCounts();
  }

  // ================= COUNTS =================
  Future<void> loadCounts() async {
    loading = true;
    notifyListeners();

    final result = await _service.loadCounts();

    pendingTasksCount = result.pendingTasks;
    activeWorkItemsCount = result.activeWorkItems;

    loading = false;
    notifyListeners();
  }

  // ================= TAB =================
  void setTab(int i) {
    index = i;
    notifyListeners();
  }

  bool handleBack() {
    if (index != 0) {
      index = 0;
      notifyListeners();
      return false; // don't pop app
    }
    return true; // allow exit
  }

  // ================= TASK CREATED =================
  Future<void> onTaskCreated() async {
    await loadCounts();
  }
}
