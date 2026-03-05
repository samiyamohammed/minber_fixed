// lib/services/notification_service.dart (FINAL PRODUCTION STABLE)

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:logger/Logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart'; // Official stable library matching Al Faruk

class NotificationService {
  static final logger = Logger(
      printer: PrettyPrinter(
          methodCount: 1, printTime: true, printEmojis: true, colors: true));

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // PRODUCTION FIX: Versioned IDs to force OS to reset notification channel settings
  static const String adhanChannelId = 'minber_prayer_v4';
  static const String weeklyChannelId = 'minber_weekly_v4';

  static Future<void> init() async {
    logger.i("[NotificationService] Initializing...");

    await _ensureTimezoneInitialized();

    const android =
        AndroidInitializationSettings('@drawable/notification_icon');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == "salawat") {
          navigatorKey.currentState?.pushNamed('/dua-dhikr');
        }
      },
    );

    await _createNotificationChannels();

    if (Platform.isAndroid) {
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
    }
    logger.i("[NotificationService] Initialization complete.");
  }

  static Future<void> _ensureTimezoneInitialized() async {
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      logger.e("Timezone Error: $e. Fallback to UTC.");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  static Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Adhan Channel: PlaySound false as per client request, but High Importance
      const AndroidNotificationChannel adhanChannel =
          AndroidNotificationChannel(
        adhanChannelId,
        'Prayer Notifications',
        description: 'Notifications for Daily Prayer Times',
        importance: Importance.max,
        playSound: false,
      );

      const AndroidNotificationChannel weeklyChannel =
          AndroidNotificationChannel(
        weeklyChannelId,
        'Weekly Notifications',
        importance: Importance.max,
      );

      await androidPlugin?.createNotificationChannel(adhanChannel);
      await androidPlugin?.createNotificationChannel(weeklyChannel);
    }
  }

  static Future<void> scheduleDailyAndWeeklyNotifications() async {
    logger.i("🚀 Starting scheduling logic...");
    final prefs = await SharedPreferences.getInstance();
    final bool disclosureAccepted =
        prefs.getBool('location_disclosure_accepted') ?? false;

    if (!disclosureAccepted) {
      logger.w("Location disclosure not accepted. Skipping.");
      return;
    }

    try {
      await _ensureTimezoneInitialized();
      await _notifications.cancelAll();

      await _runScheduling(prefs);

      if (prefs.getBool('notifications_khemis_enabled') ?? true) {
        await scheduleSalawatNotification();
      }
      logger.i("✅ Scheduled Successfully.");
    } catch (e) {
      logger.e("❌ Scheduling Failed: $e");
    }
  }

  static Future<void> _runScheduling(SharedPreferences prefs) async {
    Coordinates? coordinates;

    // GPS check with strict timeout to prevent background hang
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10));
        coordinates = Coordinates(position.latitude, position.longitude);
        await prefs.setDouble('last_known_lat', position.latitude);
        await prefs.setDouble('last_known_lng', position.longitude);
      }
    } catch (e) {
      logger.w("Live GPS failed or timed out: $e");
    }

    // Fallback to cache if GPS failed
    if (coordinates == null) {
      final lat = prefs.getDouble('last_known_lat') ?? 9.03;
      final lng = prefs.getDouble('last_known_lng') ?? 38.74;
      coordinates = Coordinates(lat, lng);
    }

    final now = tz.TZDateTime.now(tz.local);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;

    // Schedule for today and tomorrow to ensure continuity
    for (int day = 0; day <= 1; day++) {
      final date = now.add(Duration(days: day));
      final prayerTimes = PrayerTimes.today(coordinates, params);

      final Map<String, DateTime?> times = {
        "Fajr": prayerTimes.fajr,
        "Dhuhr": prayerTimes.dhuhr,
        "Asr": prayerTimes.asr,
        "Maghrib": prayerTimes.maghrib,
        "Isha": prayerTimes.isha,
      };

      for (var entry in times.entries) {
        if (entry.value == null) continue;

        final tz.TZDateTime scheduled =
            tz.TZDateTime.from(entry.value!, tz.local);
        if (scheduled.isBefore(now)) continue;

        final isEnabled =
            prefs.getBool('notifications_${entry.key.toLowerCase()}_enabled') ??
                true;
        if (!isEnabled) continue;

        await _notifications.zonedSchedule(
            (entry.key.hashCode + day),
            'Time for ${entry.key}',
            'The time for the ${entry.key} prayer has arrived.',
            scheduled,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                adhanChannelId,
                'Prayer Notifications',
                importance: Importance.max,
                priority: Priority.high,
                playSound: false,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time);
      }
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
              weeklyChannelId, 'Weekly Notifications',
              importance: Importance.max),
        ),
        payload: "salawat",
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {}
  }
}
