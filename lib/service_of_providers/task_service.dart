import 'dart:convert';
import 'package:crm/service_of_providers/task_create_service.dart';
import 'package:http/http.dart' as http;
import 'package:crm/models/models.dart';
import 'package:crm/services/auth_session.dart';
import 'package:crm/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm/service_of_providers/task_create_service.dart';

class TasksService {

  /// GET all tasks (PENDING + ACTIVE + scheduled)
  
  Future<List<TaskItem>> listTasks({DateTime? forDate}) async {
  final token = await AuthSession.getToken();
  final empId = await AuthSession.getEmpId();
  final res = await http.put(
    Uri.parse("${ApiConfig.baseUrl}/workertaskui"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "emp_id": empId,   
      "status": "pending"     // 🔥 required by backend
    }),
  );
  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception("Failed to load tasks: ${res.body}");
  }
  final decoded = jsonDecode(res.body);
  // backend may return { data: [...] } or direct list
  final List list = decoded is List
      ? decoded
      : (decoded['data'] ?? decoded['tasks'] ?? []);
  var tasks = list.map((e) => TaskItem.fromJson(e)).toList();
  // optional frontend date filter
  if (forDate != null) {
    tasks = tasks.where((t) =>
      t.scheduledAt.year == forDate.year &&
      t.scheduledAt.month == forDate.month &&
      t.scheduledAt.day == forDate.day
    ).toList();
  }
  return tasks;
}

  /// DELETE task
  Future<void> deleteTask(String taskId) async {
    final token = await AuthSession.getToken();

    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/workertaskui/$taskId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Delete failed");
    }
  }
}
