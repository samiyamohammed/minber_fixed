// // lib/services/notification_service.dart (FINAL CLEANED VERSION)

// import 'package:flutter/material.dart';
// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:logger/logger.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:adhan_dart/adhan_dart.dart';
// import '../main.dart'; // Import main.dart to access callbacks, logger, and plugins

// class NotificationService {
//   static final logger = Logger(
//       printer: PrettyPrinter(
//           methodCount: 1, printTime: true, printEmojis: true, colors: true));
//   // We get the global instance from main.dart to ensure there are no conflicts.
//   static final FlutterLocalNotificationsPlugin _notifications =
//       flutterLocalNotificationsPlugin;
//   static final GlobalKey<NavigatorState> navigatorKey =
//       GlobalKey<NavigatorState>();

//   /// The init function is now empty. All critical initialization is centralized
//   /// in the initializeNotifications() function in main.dart to prevent conflicts
//   /// between the main app process and the background alarm process.
//   static Future<void> init() async {
//     logger.i(
//         "[NotificationService] init() called. Initialization is now handled by main().");
//     return Future.value();
//   }

//   /// This function is the entry point for scheduling all notifications.
//   static Future<void> scheduleDailyAndWeeklyNotifications() async {
//     logger.i("🚀 Starting notification scheduling process...");
//     try {
//       final prefs = await SharedPreferences.getInstance();

//       // Schedule Salawat reminder if enabled
//       if (prefs.getBool('notifications_khemis_enabled') ?? true) {
//         await scheduleSalawatNotification();
//       } else {
//         logger.i("Skipping Khemis notification as it's disabled by the user.");
//       }

//       // Get location and schedule prayer time alarms
//       Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.medium);
//       _scheduleAllPrayerTimesForLocation(position.latitude, position.longitude);
//     } catch (e, s) {
//       logger.e("❌ Failed to complete notification scheduling.",
//           error: e, stackTrace: s);
//     }
//   }

//   /// This is the core logic that calculates prayer times and sets the alarms.
//   static Future<void> _scheduleAllPrayerTimesForLocation(
//       double lat, double lng) async {
//     logger.i("--- Starting Alarm Scheduling for Location ---");
//     final prefs = await SharedPreferences.getInstance();
//     final prayerTimes = PrayerTimes(
//         coordinates: Coordinates(lat, lng),
//         date: DateTime.now(),
//         calculationParameters: CalculationMethod.muslimWorldLeague()
//           ..madhab = Madhab.shafi);

//     final prayers = {
//       "fajr": prayerTimes.fajr!.toLocal(),
//       "dhuhr": prayerTimes.dhuhr!.toLocal(),
//       "asr": prayerTimes.asr!.toLocal(),
//       "maghrib": prayerTimes.maghrib!.toLocal(),
//       "isha": prayerTimes.isha!.toLocal(),
//     };

//     for (var prayer in prayers.entries) {
//       final prayerKey = prayer.key;
//       final prayerTime = prayer.value;
//       final isEnabled =
//           prefs.getBool('notifications_${prayerKey}_enabled') ?? true;

//       final alarmId = prayerKey.hashCode;

//       if (isEnabled) {
//         if (prayerTime.isAfter(DateTime.now())) {
//           logger.i("✅ Scheduling ALARM for $prayerKey at $prayerTime.");
//           await AndroidAlarmManager.oneShotAt(
//             prayerTime,
//             alarmId,
//             fireAdhanAlarm, // The function from main.dart
//             exact: true,
//             wakeup: true,
//             allowWhileIdle: true,
//             rescheduleOnReboot: true,
//             params: {
//               'prayerName': prayerKey[0].toUpperCase() + prayerKey.substring(1)
//             },
//           );
//         } else {
//           logger.w(
//               "⚠️ Skipping alarm for $prayerKey as its time has already passed for today.");
//         }
//       } else {
//         logger.i(
//             "Skipping $prayerKey alarm as it's disabled. Cancelling any existing one.");
//         await AndroidAlarmManager.cancel(alarmId);
//       }
//     }
//     logger.i("--- Finished Alarm Scheduling ---");
//   }

//   /// This handler is now only for foreground taps on non-Adhan notifications.
//   /// The main background handler is in main.dart.
//   static void _handleNotificationTap(String? payload) {
//     if (payload == "salawat") {
//       navigatorKey.currentState?.pushNamed('/dua-dhikr');
//     }
//   }

//   /// Schedules the weekly Salawat reminder (uses the old notification system).
//   static Future<void> scheduleSalawatNotification() async {
//     logger.i("--- Scheduling Weekly Salawat Notification ---");
//     try {
//       final location = tz.local;
//       final now = tz.TZDateTime.now(location);
//       tz.TZDateTime scheduledDate =
//           tz.TZDateTime(location, now.year, now.month, now.day, 19);
//       if (scheduledDate.weekday != DateTime.thursday) {
//         scheduledDate = scheduledDate.add(Duration(
//             days: (DateTime.thursday - scheduledDate.weekday + 7) % 7));
//       } else if (scheduledDate.isBefore(now)) {
//         scheduledDate = scheduledDate.add(const Duration(days: 7));
//       }

//       await _notifications.zonedSchedule(
//         777,
//         "Salawat Reminder",
//         "Join in Salawat Askār this evening at 7PM",
//         scheduledDate,
//         const NotificationDetails(
//           android: AndroidNotificationDetails(
//               'weekly_channel', 'Weekly Notifications',
//               channelDescription: 'Reminder for Salawat Askār',
//               importance: Importance.max,
//               priority: Priority.high),
//           iOS: DarwinNotificationDetails(),
//         ),
//         payload: "salawat",
//         uiLocalNotificationDateInterpretation:
//             UILocalNotificationDateInterpretation.absoluteTime,
//         matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       );
//     } catch (e, s) {
//       logger.e("❌ ERROR scheduling Salawat notification",
//           error: e, stackTrace: s);
//     }
//   }

//   static Future<void> cancelAllNotifications() async {
//     logger.w("Cancelling all scheduled notifications and alarms.");
//     await _notifications.cancelAll();
//     // In the future, you could add logic here to cancel all alarms.
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan_dart/adhan_dart.dart';
import '../main.dart';
import 'adhan_background_service.dart';

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
    // 1. Initialize Timezones
    try {
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      logger.i("-> Timezones initialized successfully for ${tz.local.name}.");
    } catch (e) {
      logger.f("💀 FATAL: FAILED to initialize timezones.", error: e);
      return;
    }

    // 2. Initialize FlutterLocalNotifications
    const android =
        AndroidInitializationSettings('@drawable/notification_icon');
    const settings = InitializationSettings(android: android);

    // Link the background tap handler from adhan_background_service.dart
    await _notifications.initialize(settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) =>
            _handleNotificationTap(response.payload),
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground);

    // 3. Request necessary permissions
    if (Platform.isAndroid) {
      if (await Permission.notification.request().isGranted) {
        await Permission.scheduleExactAlarm.request();
      }
    }
    logger.i("[NotificationService] Initialization complete.");
  }

  static Future<void> scheduleDailyAndWeeklyNotifications() async {
    // This function is correct and unchanged.
    logger.i("🚀 Starting notification scheduling process...");
    try {
      final prefs = await SharedPreferences.getInstance();

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

  static Future<void> _scheduleAllPrayerTimesForLocation(
      double lat, double lng) async {
    // This logic is correct and unchanged. It schedules the alarms.
    logger.i("--- Starting Alarm Scheduling for Location ---");
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
      final isEnabled =
          prefs.getBool('notifications_${prayerKey}_enabled') ?? true;

      final alarmId = prayerKey.hashCode;

      if (isEnabled) {
        if (prayerTime.isAfter(DateTime.now())) {
          logger.i("✅ Scheduling ALARM for $prayerKey at $prayerTime.");
          await AndroidAlarmManager.oneShotAt(
            prayerTime,
            alarmId,
            fireAdhanAlarm, // The function from main.dart
            exact: true,
            wakeup: true,
            allowWhileIdle: true,
            rescheduleOnReboot: true,
            params: {
              'prayerName': prayerKey[0].toUpperCase() + prayerKey.substring(1)
            },
          );
        } else {
          logger.w(
              "⚠️ Skipping alarm for $prayerKey as its time has already passed today.");
        }
      } else {
        logger.i(
            "Skipping $prayerKey alarm as it's disabled. Cancelling any existing one.");
        await AndroidAlarmManager.cancel(alarmId);
      }
    }
    logger.i("--- Finished Alarm Scheduling ---");
  }

  static void _handleNotificationTap(String? payload) {
    if (payload == "salawat") {
      navigatorKey.currentState?.pushNamed('/dua-dhikr');
    }
  }

  static Future<void> scheduleSalawatNotification() async {
    // This function for Salawat reminders is correct and unchanged.
    logger.i("--- Scheduling Weekly Salawat Notification ---");
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
