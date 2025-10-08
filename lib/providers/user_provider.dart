// lib/providers/user_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';

// import 'package.flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 1. A simple model class to hold our user data
class UserModel {
  final String id;
  final String username;
  final String email;

  UserModel({required this.id, required this.username, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? 'Guest',
      email: json['email'] ?? '',
    );
  }
}

// 2. The Provider class that will manage the data
class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  // The main function to fetch data from your API
  Future<void> fetchUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final userId = prefs.getString('userId');

    // If there's no token or userId, we can't fetch the user
    if (token == null || userId == null) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Use the GET /users/{id} endpoint from your Swagger docs
      final url = Uri.parse('http://msa.merkuz.com:3636/users/$userId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Standard way to send the token
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = UserModel.fromJson(data);
      } else {
        // Handle error, maybe log out user if token is invalid
        print('Failed to fetch user: ${response.statusCode}');
      }
    } catch (e) {
      print('An error occurred while fetching user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
