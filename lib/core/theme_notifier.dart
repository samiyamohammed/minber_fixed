import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. The single, global theme notifier for the entire app.
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

// 2. The function to save the user's preference.
Future<void> saveThemePreference(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('themeMode', mode.index);
}

// 3. The function to load the user's preference on startup.
Future<void> loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('themeMode') ?? ThemeMode.system.index;
  themeNotifier.value = ThemeMode.values[themeIndex];
}
