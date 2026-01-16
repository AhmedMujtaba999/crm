import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyToken = 'auth_token';
  static const _keyEmail = 'auth_email';

  /// LOGIN (local now, API later)
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    // ✅ LOCAL MOCK (replace with API later)
    if (email == 'admin@poolpro.com' && password == '123456') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, 'local_mock_token');
      await prefs.setString(_keyEmail, email);
      return true;
    }

    return false;
  }

  /// CHECK LOGIN STATE
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyToken);
  }

  /// LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyEmail);
  }
}
