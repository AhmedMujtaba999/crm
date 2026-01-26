import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:crm/models/models.dart';
import 'package:flutter/material.dart';

class WorkItemsService {
  /// 🔹 GET ACTIVE WORK ITEMS FROM API
  Future<List<WorkItem>> getActiveWorkItems({
    required String empId,
    required DateTime date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final url = '${ApiConfig.baseUrl}/workertaskui/$empId/$dateStr/active';

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
      debugPrint('Active Work Items API Response: $data');

      // ✅ Convert API JSON → WorkItem model
      return data.map((e) => WorkItem.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to get active work items: $e');
    }
  }

  /// 🔹 GET SINGLE WORK ITEM FROM API BY ID
  Future<WorkItem?> getWorkItemById({required String id}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final url = '${ApiConfig.baseUrl}/workertaskui/$id';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to load work item $id: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      debugPrint('Single Work Item API Response: $data');

      // ✅ Convert API JSON → WorkItem model
      return WorkItem.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get work item by ID: $e');
    }
  }
  Future<void> updateTaskStatus({
  required String taskId,
  required String status,
  required bool sendInvoice,
  required bool sendPictures,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null) {
    throw Exception("User not authenticated (token missing)");
  }

  final url = Uri.parse("${ApiConfig.baseUrl}/workertaskui/$taskId");

  final res = await http.put(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "status": status.toUpperCase(), // ✅ ensure backend format
      "send_invoice": sendInvoice,
      "send_pictures": sendPictures,
    }),
  );

  // ✅ Accept both success codes
  if (res.statusCode != 200 && res.statusCode != 204) {
    debugPrint("Update failed: ${res.statusCode}");
    debugPrint("Response body: ${res.body}");
    throw Exception("Failed to update task status");
  }
}


  Future<List<WorkItem>> getCompletedWorkItems({
    required String empId,
    required DateTime date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final url = '${ApiConfig.baseUrl}/workertaskui/$empId/$dateStr/completed';

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
      debugPrint('Completed Work Items API Response: $data');
      return data.map((e) => WorkItem.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to get completed work items: $e');
    }
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
