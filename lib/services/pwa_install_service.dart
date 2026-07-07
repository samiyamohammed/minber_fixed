import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class PWAInstallService {
  /// Returns true if the app can be installed (install prompt is available)
  static bool canInstall() {
    if (!kIsWeb) return false;
    try {
      return js.context.callMethod('isPWAInstallAvailable', []) as bool;
    } catch (e) {
      return false;
    }
  }

  /// Returns true if already running as installed PWA
  static bool isInstalled() {
    if (!kIsWeb) return false;
    try {
      return js.context.callMethod('isPWAInstalled', []) as bool;
    } catch (e) {
      return false;
    }
  }

  /// Triggers the native browser install prompt
  static void promptInstall() {
    if (!kIsWeb) return;
    try {
      js.context.callMethod('triggerPWAInstall', []);
    } catch (e) {
      debugPrint('PWA install error: $e');
    }
  }
}
