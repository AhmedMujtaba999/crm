import 'package:flutter/material.dart';
import 'package:crm/service_of_providers/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool loading = false;
  bool loggedIn = false;

  Future<void> checkAuth() async {
    loggedIn = await _service.isLoggedIn();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    loading = true;
    notifyListeners();

    final success = await _service.login(
      email: email,
      password: password,
    );

    loggedIn = success;
    loading = false;
    notifyListeners();

    return success;
  }

  Future<void> logout() async {
    await _service.logout();
    loggedIn = false;
    notifyListeners();
  }
}
