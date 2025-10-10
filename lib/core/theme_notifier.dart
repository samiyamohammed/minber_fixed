// lib/core/theme_notifier.dart (Fully Corrected & Ready to Paste)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The key we'll use to save the theme preference in SharedPreferences.
const String _themePrefKey = 'themeMode';

/// This is the single, global source of truth for the app's theme.
/// It will be initialized in main.dart after loading the saved preference.
late final ValueNotifier<ThemeMode> themeNotifier;

/// Saves the user's chosen theme mode to persistent storage.
Future<void> saveThemePreference(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  // We save the index of the enum (e.g., ThemeMode.dark.index is 1)
  await prefs.setInt(_themePrefKey, mode.index);
}

/// Loads the user's saved theme mode from persistent storage.
///
/// Defaults to ThemeMode.system if no preference is found.
Future<ThemeMode> loadThemePreference() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    // Get the saved index, defaulting to the system theme's index if null
    final savedThemeIndex =
        prefs.getInt(_themePrefKey) ?? ThemeMode.system.index;

    // Convert the integer index back into a ThemeMode enum value
    if (savedThemeIndex >= 0 && savedThemeIndex < ThemeMode.values.length) {
      return ThemeMode.values[savedThemeIndex];
    }
  } catch (e) {
    // If something goes wrong, log it and fall back to a safe default
    debugPrint("Error loading theme preference: $e");
  }

  // Fallback to system theme if anything fails
  return ThemeMode.system;
}
