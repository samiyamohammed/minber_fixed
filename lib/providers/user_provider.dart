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
bool _isLoading = false;
final logger = Logger();
UserModel? get user => _user;
String? get accessToken => _accessToken;
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
  _accessToken = data['accessToken']; // Corrected to camelCase

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('accessToken', _accessToken!);
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
if (token != null && userJsonString != null) {
  _user = UserModel.fromJson(userModelAsMap(userJsonString));
  _accessToken = token;
  logger.i("Loaded user '${_user!.username}' from storage.");
  notifyListeners();
} else {
  logger.w("No user data found in storage.");
}
}
/// Logs the user out and clears all session data.
Future<void> logout() async {
_user = null;
_accessToken = null;
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('isLoggedIn', false);
await prefs.remove('accessToken');
await prefs.remove('user');

logger.i("User logged out and all session data cleared.");
notifyListeners();
}
}