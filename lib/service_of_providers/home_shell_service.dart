import '../storage.dart';

class HomeShellCounts {
  final int pendingTasks;
  final int activeWorkItems;

  HomeShellCounts({
    required this.pendingTasks,
    required this.activeWorkItems,
  });
}

class HomeShellService {
  Future<HomeShellCounts> loadCounts() async {
   // await AppDb.instance.seedTasksIfEmpty();

   // final tasks = await AppDb.instance.listTasks();
    final work = await AppDb.instance.listWorkItemsByStatus('active');

    final today = DateTime.now();

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    // final pendingToday =
    //     tasks.where((t) => isSameDay(t.scheduledAt, today)).length;

    return HomeShellCounts(
      pendingTasks: 0,
      activeWorkItems: work.length,
    );
  }
}
