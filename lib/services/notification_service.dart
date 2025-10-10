// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_timezone/flutter_timezone.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:logger/logger.dart';

// // --- ADDED IMPORTS FOR LOCATION AND PRAYER CALCULATION ---
// import 'package:geolocator/geolocator.dart';
// import 'package:adhan_dart/adhan_dart.dart';

// class NotificationService {
//   static final logger = Logger(
//     printer: PrettyPrinter(
//       methodCount: 1,
//       printTime: true,
//       printEmojis: true,
//       colors: true,
//     ),
//   );

//   static final FlutterLocalNotificationsPlugin _notifications =
//       FlutterLocalNotificationsPlugin();

//   static final GlobalKey<NavigatorState> navigatorKey =
//       GlobalKey<NavigatorState>();

//   static Future<void> init() async {
//     try {
//       logger.i("Initializing timezone database...");
//       tz.initializeTimeZones();
//       final String timeZoneName = await FlutterTimezone.getLocalTimezone();
//       tz.setLocalLocation(tz.getLocation(timeZoneName));
//       logger.i("✅ Timezone database initialized for location: $timeZoneName");
//       logger.d("🌍 Current time in local TZ: ${tz.TZDateTime.now(tz.local)}");
//     } catch (e, s) {
//       logger.f(
//         "💀 FATAL: FAILED to initialize timezones. Notifications will NOT work.",
//         error: e,
//         stackTrace: s,
//       );
//       return;
//     }

//         const android =
//         AndroidInitializationSettings('@drawable/notification_icon');
//     const ios = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//     const settings = InitializationSettings(android: android, iOS: ios);

//     await _notifications.initialize(
//       settings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         logger.i(
//           'Foreground notification tapped with payload: ${response.payload}',
//         );
//         _handleNotificationTap(response.payload);
//       },
//       onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
//     );

//     if (Platform.isAndroid) {
//       final status = await Permission.notification.request();
//       if (status.isGranted) {
//         logger.i("✅ Standard notification permission granted.");
//         final alarmStatus = await Permission.scheduleExactAlarm.request();
//         if (alarmStatus.isGranted) {
//           logger.i("✅ Exact alarm permission granted.");
//         } else {
//           logger.e(
//             "❌ Exact alarm permission was denied. Scheduled notifications may not work.",
//           );
//         }
//       } else {
//         logger.e("❌ Standard notification permission was denied.");
//       }
//     }
//   }

//   // --- NEW CENTRAL SCHEDULING FUNCTION ---
//   /// Fetches location and schedules all daily and weekly notifications.
//   static Future<void> scheduleDailyAndWeeklyNotifications() async {
//     logger.i("🚀 Starting daily and weekly notification scheduling process...");
//     try {
//       await scheduleSalawatNotification();

//       Position? position = await Geolocator.getLastKnownPosition();
//       position ??= await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.medium,
//       );
//       logger.d(
//         "📍 Position for scheduling: ${position.latitude}, ${position.longitude}",
//       );

//       _scheduleAllPrayerTimesForLocation(position.latitude, position.longitude);
//     } catch (e, s) {
//       logger.e(
//         "❌ Failed to complete the notification scheduling process.",
//         error: e,
//         stackTrace: s,
//       );
//     }
//   }

//   // --- NEW PRIVATE HELPER FUNCTION (LOGIC MOVED FROM PRAYER PAGE) ---
//   static void _scheduleAllPrayerTimesForLocation(double lat, double lng) {
//     logger.i(
//       "Calculating and scheduling prayer times for Lat: $lat, Lng: $lng",
//     );
//     final coordinates = Coordinates(lat, lng);
//     final params = CalculationMethod.muslimWorldLeague();
//     params.madhab = Madhab.shafi;

//     final prayerTimes = PrayerTimes(
//       coordinates: coordinates,
//       date: DateTime.now(),
//       calculationParameters: params,
//     );

//     final fajr = prayerTimes.fajr!.toLocal();
//     final dhuhr = prayerTimes.dhuhr!.toLocal();
//     final asr = prayerTimes.asr!.toLocal();
//     final maghrib = prayerTimes.maghrib!.toLocal();
//     final isha = prayerTimes.isha!.toLocal();

//     logger.i("Scheduling all prayer notifications for today...");
//     schedulePrayerNotification(
//       id: "fajr",
//       title: "Fajr Prayer",
//       body:
//           "It is time for Fajr prayer. Begin your day with remembrance of Allah.",
//       scheduledTime: fajr,
//     );
//     schedulePrayerNotification(
//       id: "dhuhr",
//       title: "Dhuhr Prayer",
//       body: "It is time for Dhuhr prayer. Take a moment to remember Allah.",
//       scheduledTime: dhuhr,
//     );
//     schedulePrayerNotification(
//       id: "asr",
//       title: "Asr Prayer",
//       body: "It is time for Asr prayer. Stand for your afternoon prayer.",
//       scheduledTime: asr,
//     );
//     schedulePrayerNotification(
//       id: "maghrib",
//       title: "Maghrib Prayer",
//       body: "It is time for Maghrib prayer. Break your fast and pray.",
//       scheduledTime: maghrib,
//     );
//     schedulePrayerNotification(
//       id: "isha",
//       title: "Isha Prayer",
//       body:
//           "It is time for Isha prayer. End your day with remembrance of Allah.",
//       scheduledTime: isha,
//     );
//   }

//   @pragma('vm:entry-point')
//   static void notificationTapBackground(NotificationResponse response) {
//     logger.i(
//       'Background notification tapped with payload: ${response.payload}',
//     );
//     _handleNotificationTap(response.payload);
//   }

//   static void _handleNotificationTap(String? payload) {
//     logger.d("Handling notification tap for payload: $payload");
//     if (payload == "salawat") {
//       navigatorKey.currentState?.pushNamed('/dua-dhikr');
//     }
//   }

//   static Future<void> schedulePrayerNotification({
//     required String id,
//     required String title,
//     required String body,
//     required DateTime scheduledTime,
//     bool repeatDaily = true,
//   }) async {
//     final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(
//       scheduledTime,
//       tz.local,
//     );

//     logger.i("--- Scheduling Prayer Notification ---");
//     logger.d({
//       "ID": id,
//       "Title": title,
//       "Device Time": DateTime.now().toIso8601String(),
//       "Scheduled Raw": scheduledTime.toIso8601String(),
//       "Scheduled TZ": scheduledTZTime.toIso8601String(),
//     });

//     if (scheduledTZTime.isBefore(tz.TZDateTime.now(tz.local))) {
//       logger.w(
//         "⚠️ Attempting to schedule '$id' for a time that has already passed. It will trigger tomorrow.",
//       );
//     } else {
//       logger.i("✅ Schedule time for '$id' is in the future. Looks good!");
//     }

//     try {
//       await _notifications.zonedSchedule(
//         id.hashCode,
//         title,
//         body,
//         scheduledTZTime,
//         const NotificationDetails(
//           android: AndroidNotificationDetails(
//             'prayer_channel',
//             'Prayer Notifications',
//             channelDescription: 'Reminders for daily prayers',
//             importance: Importance.max,
//             priority: Priority.high,
//           ),
//           iOS: DarwinNotificationDetails(),
//         ),
//         uiLocalNotificationDateInterpretation:
//             UILocalNotificationDateInterpretation.absoluteTime,
//         matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       );
//     } catch (e, s) {
//       logger.e(
//         "❌ ERROR scheduling notification with zonedSchedule",
//         error: e,
//         stackTrace: s,
//       );
//     }
//   }

//   static Future<void> scheduleSalawatNotification() async {
//     logger.i("--- Scheduling Weekly Salawat Notification ---");
//     try {
//       final location = tz.getLocation('Africa/Nairobi');
//       final now = tz.TZDateTime.now(location);

//       tz.TZDateTime scheduledDate = tz.TZDateTime(
//         location,
//         now.year,
//         now.month,
//         now.day,
//         19,
//       );

//       if (scheduledDate.weekday != DateTime.thursday) {
//         scheduledDate = scheduledDate.add(
//           Duration(days: (DateTime.thursday - scheduledDate.weekday + 7) % 7),
//         );
//       } else if (scheduledDate.isBefore(now)) {
//         scheduledDate = scheduledDate.add(const Duration(days: 7));
//       }

//       logger.d("Salawat scheduled for: ${scheduledDate.toIso8601String()}");

//       await _notifications.zonedSchedule(
//         777,
//         "Salawat Reminder",
//         "Join in Salawat Askār this evening at 7PM",
//         scheduledDate,
//         const NotificationDetails(
//           android: AndroidNotificationDetails(
//             'weekly_channel',
//             'Weekly Notifications',
//             channelDescription: 'Reminder for Salawat Askār',
//             importance: Importance.max,
//             priority: Priority.high,
//           ),
//           iOS: DarwinNotificationDetails(),
//         ),
//         payload: "salawat",
//         uiLocalNotificationDateInterpretation:
//             UILocalNotificationDateInterpretation.absoluteTime,
//         matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       );
//     } catch (e, s) {
//       logger.e(
//         "❌ ERROR scheduling Salawat notification",
//         error: e,
//         stackTrace: s,
//       );
//     }
//   }

//   static Future<void> cancelAllNotifications() async {
//     logger.w("Cancelling all scheduled notifications.");
//     await _notifications.cancelAll();
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:logger/logger.dart';

// --- ADDED IMPORTS FOR LOCATION AND PRAYER CALCULATION ---
import 'package:geolocator/geolocator.dart';
import 'package:adhan_dart/adhan_dart.dart';

class NotificationService {
  static final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      printTime: true,
      printEmojis: true,
      colors: true,
    ),
  );

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> init() async {
    try {
      logger.i("Initializing timezone database...");
      tz.initializeTimeZones();
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      logger.i("✅ Timezone database initialized for location: $timeZoneName");
      logger.d("🌍 Current time in local TZ: ${tz.TZDateTime.now(tz.local)}");
    } catch (e, s) {
      logger.f(
        "💀 FATAL: FAILED to initialize timezones. Notifications will NOT work.",
        error: e,
        stackTrace: s,
      );
      return;
    }

    const android =
        AndroidInitializationSettings('@drawable/notification_icon');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        logger.i(
          'Foreground notification tapped with payload: ${response.payload}',
        );
        _handleNotificationTap(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        logger.i("✅ Standard notification permission granted.");
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        if (alarmStatus.isGranted) {
          logger.i("✅ Exact alarm permission granted.");
        } else {
          logger.e(
            "❌ Exact alarm permission was denied. Scheduled notifications may not work.",
          );
        }
      } else {
        logger.e("❌ Standard notification permission was denied.");
      }
    }
  }

  // --- NEW CENTRAL SCHEDULING FUNCTION ---
  /// Fetches location and schedules all daily and weekly notifications.
  static Future<void> scheduleDailyAndWeeklyNotifications() async {
    logger.i("🚀 Starting daily and weekly notification scheduling process...");
    try {
      await scheduleSalawatNotification();

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      logger.d(
        "📍 Position for scheduling: ${position.latitude}, ${position.longitude}",
      );

      _scheduleAllPrayerTimesForLocation(position.latitude, position.longitude);
    } catch (e, s) {
      logger.e(
        "❌ Failed to complete the notification scheduling process.",
        error: e,
        stackTrace: s,
      );
    }
  }

  // --- NEW PRIVATE HELPER FUNCTION (LOGIC MOVED FROM PRAYER PAGE) ---
  static void _scheduleAllPrayerTimesForLocation(double lat, double lng) {
    logger.i(
      "Calculating and scheduling prayer times for Lat: $lat, Lng: $lng",
    );
    final coordinates = Coordinates(lat, lng);
    final params = CalculationMethod.muslimWorldLeague();
    params.madhab = Madhab.shafi;

    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: DateTime.now(),
      calculationParameters: params,
    );

    final fajr = prayerTimes.fajr!.toLocal();
    final dhuhr = prayerTimes.dhuhr!.toLocal();
    final asr = prayerTimes.asr!.toLocal();
    final maghrib = prayerTimes.maghrib!.toLocal();
    final isha = prayerTimes.isha!.toLocal();

    logger.i("Scheduling all prayer notifications for today...");
    schedulePrayerNotification(
      id: "fajr",
      title: "Fajr Prayer",
      body:
          "It is time for Fajr prayer. Begin your day with remembrance of Allah.",
      scheduledTime: fajr,
    );
    schedulePrayerNotification(
      id: "dhuhr",
      title: "Dhuhr Prayer",
      body: "It is time for Dhuhr prayer. Take a moment to remember Allah.",
      scheduledTime: dhuhr,
    );
    schedulePrayerNotification(
      id: "asr",
      title: "Asr Prayer",
      body: "It is time for Asr prayer. Stand for your afternoon prayer.",
      scheduledTime: asr,
    );
    schedulePrayerNotification(
      id: "maghrib",
      title: "Maghrib Prayer",
      body: "It is time for Maghrib prayer. Break your fast and pray.",
      scheduledTime: maghrib,
    );
    schedulePrayerNotification(
      id: "isha",
      title: "Isha Prayer",
      body:
          "It is time for Isha prayer. End your day with remembrance of Allah.",
      scheduledTime: isha,
    );
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    logger.i(
      'Background notification tapped with payload: ${response.payload}',
    );
    _handleNotificationTap(response.payload);
  }

  //
  // ▼▼▼▼ CHANGE #1: THE NOTIFICATION TAP HANDLER IS NOW MORE INTELLIGENT ▼▼▼▼
  //
  static void _handleNotificationTap(String? payload) {
    logger.d("Handling notification tap for payload: $payload");

    if (payload == "salawat") {
      // This correctly navigates to the Dua & Dhikr page.
      navigatorKey.currentState?.pushNamed('/dua-dhikr');
    }
    // MODIFIED: Added this 'else if' block to handle all prayer time taps.
    else if (payload == 'fajr' ||
        payload == 'dhuhr' ||
        payload == 'asr' ||
        payload == 'maghrib' ||
        payload == 'isha') {
      // For any prayer notification, go to the home screen.
      // `pushNamedAndRemoveUntil` is used to clear any existing pages,
      // making '/home' the new base page.
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }
  //
  // ▲▲▲▲ CHANGE #1: END OF MODIFICATION ▲▲▲▲
  //

  static Future<void> schedulePrayerNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool repeatDaily = true,
  }) async {
    final tz.TZDateTime scheduledTZTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    logger.i("--- Scheduling Prayer Notification ---");
    logger.d({
      "ID": id,
      "Title": title,
      "Device Time": DateTime.now().toIso8601String(),
      "Scheduled Raw": scheduledTime.toIso8601String(),
      "Scheduled TZ": scheduledTZTime.toIso8601String(),
    });

    if (scheduledTZTime.isBefore(tz.TZDateTime.now(tz.local))) {
      logger.w(
        "⚠️ Attempting to schedule '$id' for a time that has already passed. It will trigger tomorrow.",
      );
    } else {
      logger.i("✅ Schedule time for '$id' is in the future. Looks good!");
    }

    try {
      await _notifications.zonedSchedule(
        id.hashCode,
        title,
        body,
        scheduledTZTime,
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

        //
        // ▼▼▼▼ CHANGE #2: A PAYLOAD IS NOW ATTACHED TO EACH PRAYER NOTIFICATION ▼▼▼▼
        //
        // MODIFIED: Added this payload. The `id` will be "fajr", "dhuhr", etc.
        payload: id,
        //
        // ▲▲▲▲ CHANGE #2: END OF MODIFICATION ▲▲▲▲
        //

        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e, s) {
      logger.e(
        "❌ ERROR scheduling notification with zonedSchedule",
        error: e,
        stackTrace: s,
      );
    }
  }

  static Future<void> scheduleSalawatNotification() async {
    logger.i("--- Scheduling Weekly Salawat Notification ---");
    try {
      final location = tz.getLocation('Africa/Nairobi');
      final now = tz.TZDateTime.now(location);

      tz.TZDateTime scheduledDate = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        19,
      );

      if (scheduledDate.weekday != DateTime.thursday) {
        scheduledDate = scheduledDate.add(
          Duration(days: (DateTime.thursday - scheduledDate.weekday + 7) % 7),
        );
      } else if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }

      logger.d("Salawat scheduled for: ${scheduledDate.toIso8601String()}");

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
    } catch (e, s) {
      logger.e(
        "❌ ERROR scheduling Salawat notification",
        error: e,
        stackTrace: s,
      );
    }
  }

  static Future<void> cancelAllNotifications() async {
    logger.w("Cancelling all scheduled notifications.");
    await _notifications.cancelAll();
  }
}
