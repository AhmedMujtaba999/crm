import '../storage.dart';
import 'package:crm/models/models.dart';

class WorkItemsService {
  Future<List<WorkItem>> getByStatus(String status) async {
    return AppDb.instance.listWorkItemsByStatus(status);
  }

  Future<void> delete(String id) async {
    await AppDb.instance.deleteWorkItem(id);
  }
}
