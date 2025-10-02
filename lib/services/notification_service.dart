import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Navigator key to handle navigation from notifications
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Foreground notification tap
        debugPrint('Notification tapped: ${response.payload}');
        _handleNotificationTap(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  // Background notification tap handler
  static void notificationTapBackground(NotificationResponse response) {
    debugPrint('Background notification tapped: ${response.payload}');
    _handleNotificationTap(response.payload);
  }

  // Handle notification tap (both foreground & background)
  static void _handleNotificationTap(String? payload) {
    if (payload == "salawat") {
      navigatorKey.currentState?.pushNamed('/dua-dhikr');
    }
  }

  /// Daily Prayer Notification
  static Future<void> schedulePrayerNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool repeatDaily = true,
  }) async {
    await _notifications.zonedSchedule(
      id.hashCode, // unique id per prayer
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel',
          'Prayer Notifications',
          channelDescription: 'Reminders for daily prayers',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Weekly Salawat Askār (Thursday 7PM EAT)
  static Future<void> scheduleSalawatNotification() async {
    final location = tz.getLocation('Africa/Nairobi'); // EAT timezone
    final now = tz.TZDateTime.now(location);

    // Start with today at 7PM
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      19, // 7PM
    );

    // If it's not Thursday or already passed, go to next Thursday
    if (scheduledDate.isBefore(now) ||
        scheduledDate.weekday != DateTime.thursday) {
      final daysToAdd = (DateTime.thursday - scheduledDate.weekday + 7) % 7;
      scheduledDate = scheduledDate.add(Duration(days: daysToAdd));
      scheduledDate = tz.TZDateTime(
        location,
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        19,
      );
    }

    await _notifications.zonedSchedule(
      777, // unique ID for Salawat
      "Salawat Reminder",
      "Join in Salawat Askār this evening at 7PM",
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_channel',
          'Weekly Notifications',
          channelDescription: 'Reminder for Salawat Askār',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: "salawat",
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancel single notification
  static Future<void> cancelNotification(String id) async {
    await _notifications.cancel(id.hashCode);
  }

  /// Cancel all
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
