import '../storage.dart';
import '../models.dart';

class WorkItemsService {
  Future<List<WorkItem>> getByStatus(String status) async {
    return AppDb.instance.listWorkItemsByStatus(status);
  }

  Future<void> delete(int id) async {
    await AppDb.instance.deleteWorkItem(id);
  }
}
