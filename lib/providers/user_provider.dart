// lib/providers/user_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart'; // Ensure this path is correct

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  final logger = Logger();

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  UserProvider() {
    _loadUserFromPrefs(); // Attempt to load user on app startup
  }

  // ✅ NEW LOGIN LOGIC
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final String apiUrl = "http://msa.merkuz.com:3636/users/login";
    final body = jsonEncode({"email": email, "password": password});

    logger.d("Attempting login with payload: $body");

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      logger.i("Login Response Status Code: ${response.statusCode}");
      logger.d("Login Response Body: ${response.body}");

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // ✅ Correctly parse the nested user object
        _user = UserModel.fromJson(data['user']);

        final accessToken = data['accessToken'];

        // Save data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', accessToken);
        // Save the entire user object as a JSON string
        await prefs.setString('user', userModelToJson(_user!));

        logger.i("✅ Login successful. User '${_user!.username}' data stored.");

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        logger.e("Login failed. Server returned error.");
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      logger.e("An exception occurred during login",
          error: e, stackTrace: stackTrace);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ LOGIC TO PERSIST USER SESSION
  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonString = prefs.getString('user');
    final token = prefs.getString('accessToken');

    if (token != null && userJsonString != null) {
      _user = UserModel.fromJson(userModelAsMap(userJsonString));
      logger.i("Loaded user '${_user!.username}' from storage.");
      notifyListeners();
    } else {
      logger.w("No user data found in storage.");
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('user');
    logger.i("User logged out and data cleared.");
    notifyListeners();
  }
}
