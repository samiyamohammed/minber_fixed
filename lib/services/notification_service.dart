// lib/services/notification_service.dart (FINAL - WORKMANAGER VERSION)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:logger/Logger.dart';
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
    logger.i("[NotificationService] Initializing...");
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      logger.f("💀 FATAL: FAILED to initialize timezones.", error: e);
      return;
    }
    await _createNotificationChannels();
    const android =
        AndroidInitializationSettings('@drawable/notification_icon');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload == "salawat") {
        navigatorKey.currentState?.pushNamed('/dua-dhikr');
      }
    });

    if (Platform.isAndroid) {
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
    }
    logger.i("[NotificationService] Initialization complete.");
  }

  static Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel adhanChannel =
          AndroidNotificationChannel(
        'adhan_channel',
        'Adhan Notifications',
        description: 'Notifications for prayer times',
        importance: Importance.max,
      );

      const AndroidNotificationChannel weeklyChannel =
          AndroidNotificationChannel(
        'weekly_channel',
        'Weekly Notifications',
        description: 'Reminder for Salawat Askār',
        importance: Importance.max,
      );

      final FlutterLocalNotificationsPlugin notifications =
          FlutterLocalNotificationsPlugin();
      await notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(adhanChannel);
      await notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(weeklyChannel);
    }
  }

  static Future<bool> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        logger.w("Location permission denied - using cached prayer times");

        final prefs = await SharedPreferences.getInstance();
        final cachedTimesJson = prefs.getString("prayerTimesIso");

        if (cachedTimesJson != null) {
          logger.i("Using cached prayer times for notifications");
          return true;
        } else {
          logger.e("No cached prayer times available");
          return false;
        }
      }
      return true;
    } catch (e) {
      logger.e("Error checking location permission: $e");
      return false;
    }
  }

  static Future<void> scheduleDailyAndWeeklyNotifications() async {
    logger.i("🚀 Starting background notification scheduling process...");
    try {
      await _initializeForBackground();
      await _notifications.cancelAll();
      logger.i("Cleared all previously scheduled notifications.");

      await _scheduleAllPrayerTimes();

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

    if (!await _checkLocationPermission()) {
      logger.e(
          "Cannot schedule notifications without location permission or cached times");
      return;
    }
    final prefs = await SharedPreferences.getInstance();

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
    } catch (e) {
      logger.e("Could not get location for scheduling. Aborting.", error: e);
      return;
    }

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

    for (var prayer in prayersToSchedule.entries) {
      final prayerName = prayer.key;
      final prayerDateTime = prayer.value;

      if (prayerDateTime == null) continue;

      final tz.TZDateTime scheduledTime =
          tz.TZDateTime.from(prayerDateTime, tz.local);

      if (scheduledTime.isAfter(now)) {
        final isEnabled = prefs
                .getBool('notifications_${prayerName.toLowerCase()}_enabled') ??
            true;

        if (isEnabled) {
          logger.i("✅ Scheduling '$prayerName' at $scheduledTime");

          await _notifications.zonedSchedule(
            prayerName.hashCode,
            'Time for $prayerName',
            'The time for the $prayerName prayer has arrived.',
            scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'adhan_channel',
                'Adhan Notifications',
                channelDescription: 'Notifications for prayer times.',
                importance: Importance.max,
                // REMOVED: priority: Priority.high,
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

  static Future<void> _initializeForBackground() async {
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      logger.e("Error getting local timezone in background: $e");
    }
  }

  static Future<void> scheduleSalawatNotification() async {
    try {
      final location = tz.local;
      final now = tz.TZDateTime.now(location);
      tz.TZDateTime scheduledDate =
          tz.TZDateTime(location, now.year, now.month, now.day, 19);
      if (scheduledDate.weekday != DateTime.thursday) {
        scheduledDate = scheduledDate.add(Duration(
            days: (DateTime.thursday - scheduledDate.weekday + 7) % 7));
      } else if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      logger.i("Scheduling weekly Salawat notification for $scheduledDate");

      await _notifications.zonedSchedule(
        777,
        "Salawat Reminder",
        "Join in Salawat Askār this evening at 7PM",
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_channel',
            'Weekly Notifications',
            channelDescription: 'Reminder for Salawat Askār',
            importance: Importance.max,
            // REMOVED: priority: Priority.high,
          ),
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

  static Future<void> debugNotificationSetup() async {
    logger.i("🧪 DEBUG: Testing notification setup in release mode");

    await _notifications.show(
      888,
      'Test Notification',
      'If you see this, notifications work in release mode',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'adhan_channel',
          'Adhan Notifications',
          channelDescription: 'Test notification',
          importance: Importance.max,
          // REMOVED: priority: Priority.high,
        ),
      ),
    );

    logger.i("🧪 DEBUG: Test notification scheduled");
  }

  static Future<void> cancelAllNotifications() async {
    logger.w("Cancelling all scheduled notifications.");
    await _notifications.cancelAll();
  }
}
