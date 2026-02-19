// lib/services/notification_service.dart (FINAL - COMPLIANT VERSION)

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

  static Future<void> scheduleDailyAndWeeklyNotifications() async {
    logger.i("🚀 Starting background notification scheduling process...");

    // Check if the user has accepted the location disclosure first
    final prefs = await SharedPreferences.getInstance();
    final bool disclosureAccepted =
        prefs.getBool('location_disclosure_accepted') ?? false;

    if (!disclosureAccepted) {
      logger.w(
          "⚠️ Location disclosure not yet accepted. Skipping background scheduling.");
      return;
    }

    try {
      await _initializeForBackground();
      await _notifications.cancelAll();
      logger.i("Cleared all previously scheduled notifications.");

      await _scheduleAllPrayerTimes();

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

    Coordinates? coordinates;

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      // If we don't have "Always" permission yet, we don't throw an error,
      // we just try to use cached coordinates if available.
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 20));

        coordinates = Coordinates(position.latitude, position.longitude);

        // Save to cache for next time background service runs
        await prefs.setDouble('last_known_lat', position.latitude);
        await prefs.setDouble('last_known_lng', position.longitude);

        logger.i("✅ Successfully fetched live location for scheduling.");
      } else {
        logger.w(
            "Location permission not high enough for live fetch. Checking cache.");
      }
    } catch (e) {
      logger.w("Could not get live location for scheduling. Reason: $e");
    }

    // --- Try Cache if live fetch failed or wasn't allowed ---
    if (coordinates == null) {
      final lat = prefs.getDouble('last_known_lat');
      final lng = prefs.getDouble('last_known_lng');

      if (lat != null && lng != null) {
        coordinates = Coordinates(lat, lng);
        logger.i("✅ Using CACHED location for scheduling: $lat, $lng");
      }
    }

    if (coordinates != null) {
      final now = tz.TZDateTime.now(tz.local);
      final prayerTimes = PrayerTimes(
          coordinates: coordinates,
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

      for (var prayer in prayersToSchedule.entries) {
        final prayerName = prayer.key;
        final prayerDateTime = prayer.value;
        if (prayerDateTime == null) continue;

        final tz.TZDateTime scheduledTime =
            tz.TZDateTime.from(prayerDateTime, tz.local);

        if (scheduledTime.isAfter(now)) {
          final isEnabled = prefs.getBool(
                  'notifications_${prayerName.toLowerCase()}_enabled') ??
              true;
          if (isEnabled) {
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
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
          }
        }
      }
    } else {
      logger.e("❌ Could not get location. Notifications not scheduled.");
      return;
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

  static Future<void> cancelAllNotifications() async {
    logger.w("Cancelling all scheduled notifications.");
    await _notifications.cancelAll();
  }
}
