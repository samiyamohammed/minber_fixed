// lib/core/theme_notifier.dart
import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<bool> {
  ThemeNotifier(bool value) : super(value);
}

final themeNotifier = ThemeNotifier(false); // Initial state is light mode
