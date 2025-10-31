// lib/providers/user_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  final logger = Logger();
  UserModel? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _accessToken != null && _user != null;
  UserProvider() {
    _loadUserFromPrefs();
  }

  /// Logs in the user, then fetches and sends the FCM token to the server.
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.loginUser(email, password);
      logger.i("✅ Login successful from API.");

      // --- ✅ THE FIX IS HERE ---
      // Parsing the keys exactly as they appear in your screenshot.
      _user = UserModel.fromJson(data['user']);
      _accessToken = data['accessToken'];
      _refreshToken = data['refreshToken']; // Corrected to camelCase

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', _accessToken!);
      await prefs.setString('refreshToken', _refreshToken!);
      await prefs.setString('user', userModelToJson(_user!));
      await prefs.setBool('isLoggedIn', true);

      logger.i("User '${_user!.username}' and token stored.");

      await _sendFcmTokenToServer();
    } catch (e, stackTrace) {
      logger.e("An exception occurred during login",
          error: e, stackTrace: stackTrace);
      throw e; // Re-throw the exception for the UI to handle
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// This private helper function gets the token and calls the ApiService.
  Future<void> _sendFcmTokenToServer() async {
    if (_accessToken == null) {
      logger.w("Cannot send FCM token, user is not logged in.");
      return;
    }
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        logger.i("📲 Retrieved FCM Token. Sending to server...");
        await ApiService.updateFcmToken(fcmToken, _accessToken!);
      } else {
        logger.w("Could not retrieve FCM token from Firebase.");
      }
    } catch (e) {
      logger.e("🔥 Error sending FCM token to server: $e");
    }
  }

  /// Loads the user session from device storage when the app starts.
  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonString = prefs.getString('user');
    final token = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');
    if (token != null && userJsonString != null) {
      _user = UserModel.fromJson(userModelAsMap(userJsonString));
      _accessToken = token;
      _refreshToken = refreshToken;
      logger.i("Loaded user '${_user!.username}' from storage.");
      notifyListeners();
    } else {
      logger.w("No user data found in storage.");
    }
  }

  Future<void> updateTokens(
      String newAccessToken, String newRefreshToken) async {
    _accessToken = newAccessToken;
    _refreshToken = newRefreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', newAccessToken);
    await prefs.setString('refreshToken', newRefreshToken);
    logger.i("🔑 Tokens have been refreshed and saved.");
    notifyListeners();
  }

  /// Logs the user out and clears all session data.
  Future<void> logout() async {
    _user = null;
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('user');

    logger.i("User logged out and all session data cleared.");
    notifyListeners();
  }

// lib/providers/user_provider.dart (Add this inside the class)
  // Future<void> updateProfile(String name, String email) async {
  //   if (_accessToken == null) {
  //     logger.w("⚠️ Cannot update profile, no access token found.");
  //     throw Exception("Not authenticated");
  //   }

  //   _isLoading = true;
  //   notifyListeners();

  //   try {
  //     logger.i("📝 Updating profile for user '${_user?.username}'...");
  //     final updatedData =
  //         await ApiService.updateUserProfile(name, email, _accessToken!);

  //     // Update local user model and save to prefs
  //     _user = _user?.copyWith(username: name, email: email);

  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('user', userModelToJson(_user!));

  //     logger.i("✅ Profile successfully updated and saved locally.");
  //   } catch (e, stack) {
  //     logger.e("🔥 Failed to update profile: $e", stackTrace: stack);
  //     rethrow;
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }
    Future<void> updateLocalUser({required String name, required String email}) async {
    if (_user != null) {
      // Create a new user object with the updated details
      _user = _user!.copyWith(username: name, email: email);
      
      // Save the updated user object to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', userModelToJson(_user!));
      
      logger.i("✅ Local user profile updated and saved.");
      
      // Notify all listening widgets that the user data has changed
      notifyListeners();
    }
  }

}
