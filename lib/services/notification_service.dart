// lib/services/notification_service.dart (FINAL - WORKMANAGER VERSION)

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

// We no longer need the main.dart import for the old alarm function.

class NotificationService {
  static final logger = Logger(
      printer: PrettyPrinter(
          methodCount: 1, printTime: true, printEmojis: true, colors: true));
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // The init function remains mostly the same.
  static Future<void> init() async {
    logger.i("[NotificationService] Initializing...");
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
    const settings = InitializationSettings(android: android);

    // The tap handler is simplified as we don't have custom actions anymore.
    await _notifications.initialize(settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload == "salawat") {
        navigatorKey.currentState?.pushNamed('/dua-dhikr');
      }
    });

    if (Platform.isAndroid) {
      // Request permissions needed for notifications and exact alarms.
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
    }
    logger.i("[NotificationService] Initialization complete.");
  }

  // --- THIS IS THE NEW CORE FUNCTION CALLED BY WORKMANAGER ---
  static Future<void> scheduleDailyAndWeeklyNotifications() async {
    logger.i("🚀 Starting background notification scheduling process...");
    try {
      // First, ensure all plugins are ready within this background isolate.
      await _initializeForBackground();

      // Clear any notifications that were scheduled from a previous run.
      // This is crucial to prevent duplicate or old notifications.
      await _notifications.cancelAll();
      logger.i("Cleared all previously scheduled notifications.");

      // Schedule the prayer time notifications.
      await _scheduleAllPrayerTimes();

      // Also, schedule the weekly Salawat notification.
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('notifications_khemis_enabled') ?? true) {
        await scheduleSalawatNotification();
      }

      logger.i("✅ Notification scheduling process completed successfully.");
    } catch (e, s) {
      logger.e("❌ Failed to complete scheduling.", error: e, stackTrace: s);
    }
  }

  static Future<void> _scheduleAllPrayerTimes() async {
    logger.i("--- Calculating and scheduling prayer notifications ---");
    final prefs = await SharedPreferences.getInstance();

    // 1. Get User Location
    // We need this to calculate accurate prayer times.
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
    } catch (e) {
      logger.e("Could not get location for scheduling. Aborting.", error: e);
      return; // Exit if we can't get location
    }

    // 2. Calculate Prayer Times for Today
    final now = tz.TZDateTime.now(tz.local);
    final prayerTimes = PrayerTimes(
        coordinates: Coordinates(position.latitude, position.longitude),
        date: now,
        calculationParameters: CalculationMethod.muslimWorldLeague()
          ..madhab = Madhab.shafi);

    final prayersToSchedule = {
      "Fajr": prayerTimes.fajr,
      "Dhuhr": prayerTimes.dhuhr,
      "Asr": prayerTimes.asr,
      "Maghrib": prayerTimes.maghrib,
      "Isha": prayerTimes.isha,
    };

    logger.i("Prayer times calculated for today: ${now.toIso8601String()}");

    // 3. Loop Through and Schedule Each Prayer
    for (var prayer in prayersToSchedule.entries) {
      final prayerName = prayer.key;
      final prayerDateTime = prayer.value;

      if (prayerDateTime == null) continue; // Skip if a time is somehow null

      // Convert the prayer's UTC DateTime to the local timezone.
      final tz.TZDateTime scheduledTime =
          tz.TZDateTime.from(prayerDateTime, tz.local);

      // CRUCIAL CHECK: Only schedule notifications that are in the future.
      if (scheduledTime.isAfter(now)) {
        final isEnabled = prefs
                .getBool('notifications_${prayerName.toLowerCase()}_enabled') ??
            true;

        if (isEnabled) {
          logger.i("✅ Scheduling '$prayerName' at $scheduledTime");

          await _notifications.zonedSchedule(
            prayerName.hashCode, // Unique ID for each notification
            'Time for $prayerName', // Title
            'The time for the $prayerName prayer has arrived.', // Body
            scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'adhan_channel', // Use the channel you already created
                'Adhan Notifications',
                channelDescription: 'Notifications for prayer times.',
                importance: Importance.max,
                priority: Priority.high,
                // We are not specifying a custom sound, so it will use the default.
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        } else {
          logger.w(
              "🚫 Skipping '$prayerName' because it is disabled in settings.");
        }
      } else {
        logger.w(
            "🚫 Skipping '$prayerName' because its time ($scheduledTime) has already passed today.");
      }
    }
    logger.i("--- Finished scheduling prayer notifications ---");
  }

  // A helper function to ensure timezone data is available in the background.
  static Future<void> _initializeForBackground() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      logger.e("Error getting local timezone in background: $e");
    }
  }

  // --- THE REST OF THE FILE IS MOSTLY UNCHANGED ---

  static Future<void> scheduleSalawatNotification() async {
    try {
      final location = tz.local;
      final now = tz.TZDateTime.now(location);
      // Logic to find the next Thursday at 7 PM
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(location, now.year, now.month, now.day, 19); // 7 PM
      if (scheduledDate.weekday != DateTime.thursday) {
        scheduledDate = scheduledDate.add(Duration(
            days: (DateTime.thursday - scheduledDate.weekday + 7) % 7));
      } else if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      logger.i("Scheduling weekly Salawat notification for $scheduledDate");

      await _notifications.zonedSchedule(
        777, // A unique ID for this notification
        "Salawat Reminder",
        "Join in Salawat Askār this evening at 7PM",
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
              'weekly_channel', 'Weekly Notifications',
              channelDescription: 'Reminder for Salawat Askār',
              importance: Importance.max,
              priority: Priority.high),
        ),
        payload: "salawat",
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e, s) {
      logger.e("❌ ERROR scheduling Salawat", error: e, stackTrace: s);
    }
  }

  static Future<void> cancelAllNotifications() async {
    logger.w("Cancelling all scheduled notifications.");
    await _notifications.cancelAll();
  }
}
