import 'dart:async';

/// No-op compass service for native mobile/desktop builds.
class WebCompassService {
  static bool get isSupported => false;

  static bool get needsPermission => false;

  static Future<String> requestPermission() async => 'unsupported';

  static Stream<double>? start() => null;

  static void stop() {}
}
