import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationSettingsProvider with ChangeNotifier {
  // --- State variables ---
  bool _isLoading = true;
  bool _generalNotifications = true;
  bool _fajr = true;
  bool _dhuhr = true;
  bool _asr = true;
  bool _maghrib = true;
  bool _isha = true;
  bool _khemis = true;

  // --- Getters to access the state from the UI ---
  bool get isLoading => _isLoading;
  bool get generalNotifications => _generalNotifications;
  bool get fajr => _fajr;
  bool get dhuhr => _dhuhr;
  bool get asr => _asr;
  bool get maghrib => _maghrib;
  bool get isha => _isha;
  bool get khemis => _khemis;

  NotificationSettingsProvider() {
    loadSettings();
  }

  // Load all saved settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _generalNotifications =
        prefs.getBool('notifications_general_enabled') ?? true;
    _fajr = prefs.getBool('notifications_fajr_enabled') ?? true;
    _dhuhr = prefs.getBool('notifications_dhuhr_enabled') ?? true;
    _asr = prefs.getBool('notifications_asr_enabled') ?? true;
    _maghrib = prefs.getBool('notifications_maghrib_enabled') ?? true;
    _isha = prefs.getBool('notifications_isha_enabled') ?? true;
    _khemis = prefs.getBool('notifications_khemis_enabled') ?? true;
    _isLoading = false;
    notifyListeners();
  }

  // --- A single method to update any setting ---
  Future<void> updateSetting(String key, bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_${key}_enabled', newValue);

    // Update the local state
    switch (key) {
      case 'general':
        _generalNotifications = newValue;
        // Also handle the Firebase topic subscription
        if (newValue) {
          await FirebaseMessaging.instance.subscribeToTopic('all');
        } else {
          await FirebaseMessaging.instance.unsubscribeFromTopic('all');
        }
        break;
      case 'fajr':
        _fajr = newValue;
        break;
      case 'dhuhr':
        _dhuhr = newValue;
        break;
      case 'asr':
        _asr = newValue;
        break;
      case 'maghrib':
        _maghrib = newValue;
        break;
      case 'isha':
        _isha = newValue;
        break;
      case 'khemis':
        _khemis = newValue;
        break;
    }

    // Notify all listening widgets that the state has changed
    notifyListeners();
  }
}
