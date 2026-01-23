import 'package:flutter/material.dart';
import 'package:crm/service_of_providers/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool loading = false;
  bool loggedIn = false;
  String? errorMessage; // Add error message

  Future<void> checkAuth() async {
    loggedIn = await _service.isLoggedIn();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    loading = true;
    errorMessage = null; // Clear previous errors
    notifyListeners();

    try {
      final success = await _service.login(
        email: email,
        password: password,
        organizationId: '3dc3498b-7565-465f-bcbd-18b49f7762ec',
      );

      loggedIn = success;
      loading = false;
      
      if (!success) {
        errorMessage = 'Invalid email or password';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      loading = false;
      loggedIn = false;
      errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _service.logout();
    loggedIn = false;
    errorMessage = null;
    notifyListeners();
  }
}