import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';

class NotificationService {
  static final logger = Logger(
      printer: PrettyPrinter(
          methodCount: 1, printTime: true, printEmojis: true, colors: true));

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String adhanChannelId = 'minber_prayer_v5'; // Bumped version
  static const String weeklyChannelId = 'minber_weekly_v5';

  static Future<void> init() async {
    debugPrint("[NotificationService] Initializing...");
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
    await _requestExactAlarmPermission();
    debugPrint("[NotificationService] Initialization complete.");
    logger.i("[NotificationService] Initialization complete.");
  }

  /// On Android 12+ (API 31+), SCHEDULE_EXACT_ALARM requires a runtime grant.
  /// On Android 13+ (API 33+), USE_EXACT_ALARM is auto-granted for alarm apps.
  /// We request it here so the user is prompted if needed.
  static Future<void> _requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      // Request exact alarm permission (Android 13+)
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (e) {
      logger.w("[NotificationService] Exact alarm permission request failed: $e");
    }
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

      const AndroidNotificationChannel adhanChannel =
          AndroidNotificationChannel(
        adhanChannelId,
        'Prayer Notifications',
        importance: Importance.max,
        playSound: false,
        enableVibration: true,
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
    final prefs = await SharedPreferences.getInstance();

    try {
      await _ensureTimezoneInitialized();
      await _notifications.cancelAll();

      await _runScheduling(prefs);

      if (prefs.getBool('notifications_khemis_enabled') ?? true) {
        await scheduleSalawatNotification();
      }
      debugPrint("✅ [NotificationService] Scheduled Successfully.");
      logger.i("✅ Scheduled Successfully.");
    } catch (e, stack) {
      debugPrint("❌ [NotificationService] Scheduling Failed: $e\n$stack");
      logger.e("❌ Scheduling Failed: $e");
    }
  }

  static Future<void> _runScheduling(SharedPreferences prefs) async {
    Coordinates? coordinates;

    // Check if exact alarms are permitted; fall back to inexact if not
    bool canUseExact = true;
    if (Platform.isAndroid) {
      try {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        canUseExact =
            await androidPlugin?.canScheduleExactNotifications() ?? false;
        if (!canUseExact) {
          logger.w(
              "[NotificationService] Exact alarms not permitted, using inexact scheduling.");
        }
      } catch (e) {
        canUseExact = false;
      }
    }

    try {
      // In background, we check for last known location first for speed
      Position? position = await Geolocator.getLastKnownPosition();

      if (position != null) {
        coordinates = Coordinates(position.latitude, position.longitude);
      } else {
        // Fallback to manual cache
        final lat = prefs.getDouble('last_known_lat') ?? 9.03;
        final lng = prefs.getDouble('last_known_lng') ?? 38.74;
        coordinates = Coordinates(lat, lng);
      }
    } catch (e) {
      final lat = prefs.getDouble('last_known_lat') ?? 9.03;
      final lng = prefs.getDouble('last_known_lng') ?? 38.74;
      coordinates = Coordinates(lat, lng);
    }

    final now = tz.TZDateTime.now(tz.local);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;

    // Schedule for the next 7 days to ensure the user stays notified even if the app isn't opened
    for (int day = 0; day <= 6; day++) {
      final date = now.add(Duration(days: day));
      final prayerTimes = PrayerTimes(
          coordinates, DateComponents(date.year, date.month, date.day), params);

      final Map<String, DateTime?> times = {
        "Fajr": prayerTimes.fajr,
        "Dhuhr": prayerTimes.dhuhr,
        "Asr": prayerTimes.asr,
        "Maghrib": prayerTimes.maghrib,
        "Isha": prayerTimes.isha,
      };

      final Map<String, int> prayerIndex = {
        "Fajr": 0,
        "Dhuhr": 1,
        "Asr": 2,
        "Maghrib": 3,
        "Isha": 4,
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

        // Stable unique ID: day * 10 + prayerIndex (avoids hashCode collisions)
        int notificationId = day * 10 + (prayerIndex[entry.key] ?? 0);

        await _notifications.zonedSchedule(
            notificationId,
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
                icon: '@drawable/notification_icon',
              ),
            ),
            androidScheduleMode: canUseExact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime);
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
