import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  static Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    if (token == null) {
      throw Exception("No auth token found");
    }
    return token;
  }

  static Future<String> getEmpId() async {
    final token = await getToken();
    final decoded = JwtDecoder.decode(token);

    final empId = decoded['employee_id'];
    if (empId == null) {
      throw Exception("employee_id not found in token");
    }
    return empId;
  }
}
