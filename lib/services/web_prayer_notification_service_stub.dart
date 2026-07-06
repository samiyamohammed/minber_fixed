import 'package:flutter/foundation.dart';

/// No-op on mobile/desktop native builds.
class WebPrayerNotificationService {
  static Future<String> requestPermission() async => 'unsupported';

  static String getPermissionStatus() => 'unsupported';

  static Future<bool> scheduleDailyAndWeeklyNotifications({
    required double latitude,
    required double longitude,
  }) async =>
      false;

  static Future<void> clearScheduledNotifications() async {}
}
