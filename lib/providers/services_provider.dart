import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/service_item.dart';
import 'package:crm/config/api_config.dart';

class ServicesProvider extends ChangeNotifier {
  List<ServiceItem> services = [];
  bool loading = false;

  Future<void> loadServices() async {
    loading = true;
    notifyListeners();

    final res = await http.get(
      Uri.parse(ApiConfig.baseUrl + ApiConfig.serviceid),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer YOUR_TOKEN",
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      services = data.map((e) => ServiceItem.fromMap(e)).toList();
    }

    loading = false;
    notifyListeners();
  }

  ServiceItem? findByName(String name) {
    return services.firstWhere(
      (s) => s.name == name,
      orElse: () => throw Exception("Service not found"),
    );
  }
}
