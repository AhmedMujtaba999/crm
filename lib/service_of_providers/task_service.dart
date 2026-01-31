import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:crm/models/models.dart';
import 'package:crm/services/auth_session.dart';
import 'package:crm/config/api_config.dart';

class TasksService {
  String _formatDate(DateTime d) {
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "$yyyy-$mm-$dd"; // 2024-10-01
  }

  Future<List<TaskItem>> listTasks({
    required DateTime forDate,
    required String status, // PENDING / ACTIVE / etc
  }) async {
    final token = await AuthSession.getToken();
    final empId = await AuthSession.getEmpId();

    if (token == null || token.isEmpty) {
      throw Exception("Token missing. Please login again.");
    }
    if (empId == null || empId.isEmpty) {
      throw Exception("empId missing. Please login again.");
    }

    final dateStr = _formatDate(forDate);
    final statusStr = status.trim().toUpperCase();

    final url = Uri.parse(
      "${ApiConfig.baseUrl}/workertaskui/$empId/$dateStr/PENDING",
    );

    debugPrint("➡️ GET $url");

    final res = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    debugPrint("✅ STATUS: ${res.statusCode}");
    debugPrint("✅ BODY: ${res.body}");

    // If backend returns error or HTML, stop here with clear message
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Failed to load tasks (${res.statusCode}): ${res.body}");
    }

    final body = res.body.trim();
    if (body.isEmpty) return [];

    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (e) {
      throw Exception("Response is not valid JSON. Body: $body");
    }

    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      final tasks = decoded['tasks'];

      if (data is List) {
        list = data;
      } else if (tasks is List) {
        list = tasks;
      } else {
        throw Exception("Unexpected JSON shape: $decoded");
      }
    } else {
      throw Exception("Unexpected response type: ${decoded.runtimeType}");
    }

    final result = <TaskItem>[];
    for (final e in list) {
      try {
        result.add(TaskItem.fromJson(e));
      } catch (err) {
        debugPrint("❌ TaskItem.fromJson failed for item: $e");
        rethrow;
      }
    }

    return result;
  }

  Future<void> deleteTask(String taskId) async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      throw Exception("Token missing. Please login again.");
    }

    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/workertaskui/$taskId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Delete failed (${res.statusCode}): ${res.body}");
    }
  }
}
