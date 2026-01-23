import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';

class AuthService {
  static const _keyToken = 'auth_token';
  static const _keyEmail = 'auth_email';
  static const _keyEmployeeId = 'employee_id';

  static const String baseUrl = 'http://3.208.90.92:3000';

  /// LOGIN with API
  Future<bool> login({
    required String email,
    required String password,
    required String organizationId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
          'organization_id': organizationId,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet.');
        },
      );

      print("STATUS: ${response.statusCode}");
      print("RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final token =
            data['token'] ?? data['access_token'] ?? data['auth_token'];

        if (token == null) {
          throw Exception("Token missing in login response");
        }

        // 🔥 DECODE JWT TO GET EMPLOYEE ID
        final payload = Jwt.parseJwt(token);

        final employeeId = payload['employee_id'];
        if (employeeId == null) {
          throw Exception("employee_id missing in token");
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, token);
        await prefs.setString(_keyEmail, email);
        await prefs.setString(_keyEmployeeId, employeeId);

        print("LOGIN SAVED:");
        print("EMPLOYEE ID: $employeeId");

        return true;
      }

      if (response.statusCode == 401) {
        return false;
      }

      throw Exception('Login failed: ${response.statusCode}');
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<String?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmployeeId);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyToken);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
