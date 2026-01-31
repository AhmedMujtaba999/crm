import 'package:crm/config/api_config.dart';
import 'package:crm/models/models.dart';
import 'package:crm/services/auth_session.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TaskCreateService {
  Future<String> createTask({
    required String customerName,
    required String phone,
    required String email,
    required String address,
    required String title,
    required DateTime scheduledAt,
    required List<ServiceItem> services,
  }) async {
    final token = await AuthSession.getToken();
    final empId = await AuthSession.getEmpId();

    final url = Uri.parse(
      ApiConfig.baseUrl + ApiConfig.createWorkItemEndpoint,
    );

    final payload = {
      "emp_id": empId,
      "task_title": title,
      "description": title,
      "status": "PENDING", // 🔒 always pending on create
      "customer_name": customerName,
      "phone": phone,
      "email": email,
      "address": address,
      "date": scheduledAt.toIso8601String(),
      "services": services.map((s) => {
        "service_id": s.serviceid,
        "unit_price": s.amount,
      }).toList(),
    };

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(res.body);
    }

    final data = jsonDecode(res.body);

    // 🔥 IMPORTANT: backend task id
    return data["task_id"];
  }
}
