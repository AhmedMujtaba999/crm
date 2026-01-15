import '../models.dart';
import '../storage.dart';

class TasksService {
  Future<void> seedIfEmpty() {
    return AppDb.instance.seedTasksIfEmpty();
  }

  Future<List<TaskItem>> listTasks({DateTime? forDate}) {
    return AppDb.instance.listTasks(forDate: forDate);
  }

  Future<void> deleteTask(String id) {
    return AppDb.instance.deleteTask(id);
  }
}
