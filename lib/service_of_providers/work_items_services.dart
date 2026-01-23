import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:crm/models/models.dart';

class WorkItemsService {
  /// 🔹 GET ACTIVE WORK ITEMS FROM API
  Future<List<WorkItem>> getActiveWorkItems({
    required String empId,
    required DateTime date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final url =
        '${ApiConfig.baseUrl}/workertaskui/$empId/$dateStr/active';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load active work items: ${response.statusCode}',
      );
    }

    final List data = jsonDecode(response.body);

    // ✅ Convert API JSON → WorkItem model
    return data.map((e) => WorkItem.fromJson(e)).toList();
  }
 Future<List<WorkItem>> getCompletedWorkItems({
  required String empId,
  required DateTime date,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final dateStr =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  final url =
      '${ApiConfig.baseUrl}/workertaskui/$empId/$dateStr/completed';

  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to load completed work items');
  }

  final List data = jsonDecode(response.body);
  return data.map((e) => WorkItem.fromJson(e)).toList();
}

  Future<void> deleteWorkItem(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/workertaskui/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete work item');
    }
  }
}


