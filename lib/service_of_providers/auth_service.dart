
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyToken = 'auth_token';
  static const _keyEmail = 'auth_email';
  
  // TODO: Replace with your actual API base URL
  static const String baseUrl = 'http://3.208.90.92:3000';

  /// LOGIN with API
  Future<bool> login({ 
    required String email,
    required String password,
    required String organizationId,
  }) async {
    try {
      final payload = {
  'email': email.trim(),
  'password': password.trim(),
  'organization_id': organizationId, // ✅ required
};
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'), // Adjust endpoint as needed
        headers: {
          'Content-Type': 'application/json',
            'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'organization_id': organizationId,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet.');
        },
        
      );
      print("LOGIN PAYLOAD: $payload");
print("STATUS: ${response.statusCode}");
print("RESPONSE: ${response.body}");


      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Extract token from response (adjust based on your API response structure)
        final token = data['token'] ?? data['access_token'] ?? data['auth_token'];
        final userEmail = data['email'] ?? email;
        
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyToken, token);
          await prefs.setString(_keyEmail, userEmail);
          
          // Optionally store other user data
          if (data['user'] != null) {
            await prefs.setString('user_data', jsonEncode(data['user']));
          }
          
          return true;
        }
      } else if (response.statusCode == 401) {
        // Invalid credentials
        return false;
      } else {
        // Other error
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      // Log error for debugging
      print('Login error: $e');
      rethrow; // Re-throw to handle in provider
    }
    
    return false;
  }

  /// GET AUTH TOKEN
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// CHECK LOGIN STATE
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyToken);
  }

  /// LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Optional: Call API logout endpoint if available
    // try {
    //   final token = await getToken();
    //   if (token != null) {
    //     await http.post(
    //       Uri.parse('$baseUrl/auth/logout'),
    //       headers: {
    //         'Authorization': 'Bearer $token',
    //       },
    //     );
    //   }
    // } catch (e) {
    //   print('Logout API error: $e');
    // }
    
    await prefs.remove(_keyToken);
    await prefs.remove(_keyEmail);
    await prefs.remove('user_data'); // If you stored user data
  }
}