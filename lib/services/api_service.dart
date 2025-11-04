// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class ApiService {
// --- ✅ THE FIX IS HERE ---
// Using your deployed production backend URL.
  static const String _baseUrl = 'http://msa.merkuz.com:3636';

  /// Logs in the user and returns the full response data.
  static Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final url = Uri.parse('$_baseUrl/users/login');
    final body = jsonEncode({'email': email, 'password': password});
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

// Your server returns 201 on successful login
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      // Throw an exception so the UI can catch and display the error
      throw Exception(
          'Failed to login. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  /// Updates the user's FCM device token on the backend server.
  static Future<void> updateFcmToken(
      String fcmToken, String accessToken) async {
    final url = Uri.parse('$_baseUrl/users/fcm-token');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // Your JWT token
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ FCM token successfully updated on the server.');
      } else {
        debugPrint('❌ Failed to update FCM token on server.');
        debugPrint('Status Code: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Network error while updating FCM token: $e');
    }
  }
// lib/services/api_service.dart (Add this below the other methods)

  static Future<Map<String, dynamic>> updateUserProfile(
      String name, String email, String accessToken) async {
    final url = Uri.parse('$_baseUrl/users/profile');
    final body = jsonEncode({
      'name': name,
      'email': email,
    });

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      debugPrint('✅ Profile updated successfully: ${response.body}');
      return jsonDecode(response.body);
    } else {
      debugPrint('❌ Failed to update profile: ${response.body}');
      throw Exception(
          'Failed to update profile. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
