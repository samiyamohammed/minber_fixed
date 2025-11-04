// lib/services/notification_service.dart (Fully Updated & Ready to Paste)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan_dart/adhan_dart.dart';

class NotificationService {
  static final logger = Logger(
      printer: PrettyPrinter(
          methodCount: 1, printTime: true, printEmojis: true, colors: true));
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> init() async {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      logger.f("💀 FATAL: FAILED to initialize timezones.", error: e);
      return;
    }
    const android =
        AndroidInitializationSettings('@drawable/notification_icon');
    const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true);
    const settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) =>
            _handleNotificationTap(response.payload),
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground);
    if (Platform.isAndroid) {
      if (await Permission.notification.request().isGranted) {
        await Permission.scheduleExactAlarm.request();
      }
    }
  }

  static Future<void> scheduleDailyAndWeeklyNotifications() async {
    // await ensureInitialized();
    logger.i("🚀 Starting notification scheduling process...");
    try {
      final prefs =
          await SharedPreferences.getInstance(); // ✅ 2. GET PREFERENCES

      // ✅ 3. CHECK PREFERENCE BEFORE SCHEDULING KHEMIS
      if (prefs.getBool('notifications_khemis_enabled') ?? true) {
        await scheduleSalawatNotification();
      } else {
        logger.i("Skipping Khemis notification as it's disabled by the user.");
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      _scheduleAllPrayerTimesForLocation(position.latitude, position.longitude);
    } catch (e, s) {
      logger.e("❌ Failed to complete notification scheduling.",
          error: e, stackTrace: s);
    }
  }

  // ✅ 4. THIS ENTIRE FUNCTION IS NOW WRAPPED IN CHECKS
  static Future<void> _scheduleAllPrayerTimesForLocation(
      double lat, double lng) async {
    logger.i("Calculating prayer times for Lat: $lat, Lng: $lng");

    final prefs = await SharedPreferences.getInstance();
    final prayerTimes = PrayerTimes(
        coordinates: Coordinates(lat, lng),
        date: DateTime.now(),
        calculationParameters: CalculationMethod.muslimWorldLeague()
          ..madhab = Madhab.shafi);

    final prayers = {
      "fajr": prayerTimes.fajr!.toLocal(),
      "dhuhr": prayerTimes.dhuhr!.toLocal(),
      "asr": prayerTimes.asr!.toLocal(),
      "maghrib": prayerTimes.maghrib!.toLocal(),
      "isha": prayerTimes.isha!.toLocal(),
    };

    for (var prayer in prayers.entries) {
      final prayerKey = prayer.key;
      final prayerTime = prayer.value;
      // Default to true if the setting doesn't exist yet
      final isEnabled =
          prefs.getBool('notifications_${prayerKey}_enabled') ?? true;

      if (isEnabled) {
        logger.i("✅ Scheduling notification for $prayerKey.");
        schedulePrayerNotification(
          id: prayerKey,
          title:
              "${prayerKey[0].toUpperCase()}${prayerKey.substring(1)} Prayer",
          body: "It's time for the ${prayerKey} prayer.",
          scheduledTime: prayerTime,
        );
      } else {
        logger.i(
            "Skipping $prayerKey notification as it's disabled by the user.");
        // If disabled, we should also cancel any previously scheduled notification for it
        await _notifications.cancel(prayerKey.hashCode);
      }
    }
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    _handleNotificationTap(response.payload);
  }

  static void _handleNotificationTap(String? payload) {
    if (payload == "salawat") {
      navigatorKey.currentState?.pushNamed('/dua-dhikr');
    }
  }

  static Future<void> schedulePrayerNotification(
      {required String id,
      required String title,
      required String body,
      required DateTime scheduledTime,
      bool repeatDaily = true}) async {
    final tz.TZDateTime scheduledTZTime =
        tz.TZDateTime.from(scheduledTime, tz.local);
    if (scheduledTZTime.isBefore(tz.TZDateTime.now(tz.local))) {
      logger.w(
          "⚠️ Scheduling '$id' for a time that has passed. It will trigger tomorrow.");
    }
    try {
      await _notifications.zonedSchedule(
        id.hashCode,
        title,
        body,
        scheduledTZTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
              'prayer_channel', 'Prayer Notifications',
              channelDescription: 'Reminders for daily prayers',
              importance: Importance.max,
              priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e, s) {
      logger.e("❌ ERROR scheduling with zonedSchedule",
          error: e, stackTrace: s);
    }
  }

  static Future<void> scheduleSalawatNotification() async {
    logger.i("--- Scheduling Weekly Salawat Notification ---");
    try {
      final location = tz.local; // Use local timezone
      final now = tz.TZDateTime.now(location);
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(location, now.year, now.month, now.day, 19);
      if (scheduledDate.weekday != DateTime.thursday) {
        scheduledDate = scheduledDate.add(Duration(
            days: (DateTime.thursday - scheduledDate.weekday + 7) % 7));
      } else if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      await _notifications.zonedSchedule(
        777,
        "Salawat Reminder",
        "Join in Salawat Askār this evening at 7PM",
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
              'weekly_channel', 'Weekly Notifications',
              channelDescription: 'Reminder for Salawat Askār',
              importance: Importance.max,
              priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
        payload: "salawat",
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e, s) {
      logger.e("❌ ERROR scheduling Salawat notification",
          error: e, stackTrace: s);
    }
  }

  static Future<void> cancelAllNotifications() async {
    logger.w("Cancelling all scheduled notifications.");
    await _notifications.cancelAll();
  }
}
