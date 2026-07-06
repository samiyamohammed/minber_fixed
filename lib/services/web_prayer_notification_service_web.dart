import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Schedules prayer reminders in the installed PWA via the service worker.
class WebPrayerNotificationService {
  static Future<String> requestPermission() async {
    try {
      final result =
          await js.context.callMethod('requestPrayerNotificationPermission', []);
      return result?.toString() ?? 'denied';
    } catch (e) {
      debugPrint('[WebPrayerNotificationService] Permission error: $e');
      return 'denied';
    }
  }

  static String getPermissionStatus() {
    try {
      return js.context
              .callMethod('getPrayerNotificationPermission', [])
              ?.toString() ??
          'unsupported';
    } catch (e) {
      return 'unsupported';
    }
  }

  static Future<bool> scheduleDailyAndWeeklyNotifications({
    required double latitude,
    required double longitude,
  }) async {
    final permission = getPermissionStatus();
    if (permission != 'granted') {
      final requested = await requestPermission();
      if (requested != 'granted') {
        debugPrint('[WebPrayerNotificationService] Permission denied: $requested');
        return false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final settings = _loadSettings(prefs);
    final schedule = _buildSchedule(latitude, longitude, prefs);

    try {
      final result = await js.context.callMethod('schedulePrayerNotifications', [
        jsonEncode(schedule),
        jsonEncode(settings),
      ]);
      return result == true;
    } catch (e) {
      debugPrint('[WebPrayerNotificationService] Schedule error: $e');
      return false;
    }
  }

  static Future<void> clearScheduledNotifications() async {
    try {
      js.context.callMethod('clearPrayerNotifications', []);
    } catch (e) {
      debugPrint('[WebPrayerNotificationService] Clear error: $e');
    }
  }

  static Map<String, bool> _loadSettings(SharedPreferences prefs) {
    return {
      'fajr': prefs.getBool('notifications_fajr_enabled') ?? true,
      'dhuhr': prefs.getBool('notifications_dhuhr_enabled') ?? true,
      'asr': prefs.getBool('notifications_asr_enabled') ?? true,
      'maghrib': prefs.getBool('notifications_maghrib_enabled') ?? true,
      'isha': prefs.getBool('notifications_isha_enabled') ?? true,
      'khemis': prefs.getBool('notifications_khemis_enabled') ?? true,
    };
  }

  static List<Map<String, String>> _buildSchedule(
    double latitude,
    double longitude,
    SharedPreferences prefs,
  ) {
    final coordinates = Coordinates(latitude, longitude);
    final params = CalculationMethod.muslim_world_league.getParameters()
      ..madhab = Madhab.shafi;

    final now = DateTime.now();
    final schedule = <Map<String, String>>[];

    for (int day = 0; day <= 6; day++) {
      final date = now.add(Duration(days: day));
      final prayerTimes = PrayerTimes(
        coordinates,
        DateComponents(date.year, date.month, date.day),
        params,
      );

      final prayers = {
        'fajr': prayerTimes.fajr,
        'dhuhr': prayerTimes.dhuhr,
        'asr': prayerTimes.asr,
        'maghrib': prayerTimes.maghrib,
        'isha': prayerTimes.isha,
      };

      for (final entry in prayers.entries) {
        final time = entry.value;
        if (time == null) continue;
        final localTime = time.toLocal();
        if (localTime.isBefore(now)) continue;

        final name = entry.key[0].toUpperCase() + entry.key.substring(1);
        schedule.add({
          'key': '${entry.key}-$day',
          'settingKey': entry.key,
          'iso': localTime.toIso8601String(),
          'title': 'Time for $name',
          'body': 'The time for the $name prayer has arrived.',
          'type': 'prayer',
        });
      }
    }

    if (prefs.getBool('notifications_khemis_enabled') ?? true) {
      schedule.addAll(_buildKhemisSchedule(now));
    }

    return schedule;
  }

  static List<Map<String, String>> _buildKhemisSchedule(DateTime now) {
    var scheduled = DateTime(now.year, now.month, now.day, 19);
    if (scheduled.weekday != DateTime.thursday) {
      scheduled = scheduled.add(
        Duration(days: (DateTime.thursday - scheduled.weekday + 7) % 7),
      );
    } else if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return [
      {
        'key': 'khemis-${scheduled.toIso8601String()}',
        'settingKey': 'khemis',
        'iso': scheduled.toIso8601String(),
        'title': 'Salawat Reminder',
        'body': 'Join in Salawat Askār this evening at 7PM',
        'type': 'salawat',
      },
    ];
  }
}
