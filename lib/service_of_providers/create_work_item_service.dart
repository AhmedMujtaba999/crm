import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'package:crm/models/models.dart';

class CreateWorkItemService {
  static const String baseUrl = ApiConfig.baseUrl;

  Future<List<ServiceCatalogItem>> getServiceCatalog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.serviceid}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        print("RAW SERVICE CATALOG DATA: $data");
        return data.map((e) => ServiceCatalogItem.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load services: ${response.statusCode}');
      }
    } catch (e) {
      print('Get services error: $e');
      rethrow;
    }
  }

  Future<bool> customerExists({
    required String phone,
    required String email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.checkCustomerEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'phone': phone, 'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false; // Adjust based on your API response
      }
      return false;
    } catch (e) {
      print('Customer exists check error: $e');
      return false; // Fallback to allow creation
    }
  }

  Future<WorkItem?> findLatestByCustomer({
    required String phone,
    required String email,
  }) async {
    // This might need a separate API endpoint or be removed if not needed
    // For now, return null to disable the existing customer dialog
    return null;
  }

  Future<WorkItemCreateResponse> save({
    required String customerName,
    required String phone,
    required String email,
    required String address,
    required String notes,
    required List<ServiceItem> services,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final empId = prefs.getString('employee_id');

      print("ALL PREF KEYS: ${prefs.getKeys()}");

      if (empId == null) {
        throw Exception("Employee not logged in");
      }

      // TODO: Add scheduled date - you might want to add a date picker to the UI
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Convert services to API format
      final apiServices = services
          .map(
            (service) => {
              "service_id":
                  service.serviceid, // TODO: Map service names to IDs later
              "quantity": 1,
              "unit_price": service.amount,
            },
          )
          .toList();

      final requestBody = {
        "date": dateStr,
        "task_title": "Work Item - $customerName",
        "description": (notes == null || notes.trim().isEmpty)
            ? "No additional notes"
            : notes.trim(),
        "emp_id": empId,
        "status": "ACTIVE",
        "customer_name": customerName,
        "phone": phone,
        "email": email,
        "address": address,
        "services": apiServices,
      };
      print("DESCRIPTION SENT => '${requestBody["description"]}'");
      print("FULL REQUEST BODY => ${jsonEncode(requestBody)}");

      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.createWorkItemEndpoint}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Connection timeout. Please check your internet.',
              );
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return WorkItemCreateResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to create work item: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Create work item error: $e');
      rethrow;
    }
  }
}

class WorkItemCreateResponse {
  final bool success;
  final String taskId;
  final String leadId;
  final String message;

  WorkItemCreateResponse({
    required this.success,
    required this.taskId,
    required this.leadId,
    required this.message,
  });

  factory WorkItemCreateResponse.fromJson(Map<String, dynamic> json) {
    return WorkItemCreateResponse(
      success: json['success'] ?? false,
      taskId: json['task_id'] ?? '',
      leadId: json['lead_id'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
