// lib/services/firebase-notification.dart (Corrected & Ready to Paste)

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:minber_super_app_new_fixed/services/notification_service.dart';

class FirebaseNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // --- [UNCHANGED] Your init() method is correct ---
  static Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@drawable/notification_icon');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final navigator = NotificationService.navigatorKey.currentState;
        if (navigator != null) {
          navigator.pushNamed('/notifications');
        }
      },
    );

    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // --- ✅ NEW METHOD: HANDLES THE IN-APP POPUP ---
  /// Shows a custom SnackBar popup when the app is in the foreground.
  static void showInAppPopup({
    required String title,
    required String body,
  }) {
    // This is the key: Use the navigatorKey from your existing NotificationService
    // to find the current screen's context.
    final BuildContext? context =
        NotificationService.navigatorKey.currentContext;

    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body.isNotEmpty) Text(body),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(15, 5, 15, 10),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              NotificationService.navigatorKey.currentState
                  ?.pushNamed('/notifications');
            },
          ),
        ),
      );
    }
  }

  // --- [UNCHANGED] This method is still needed for background/terminated notifications ---
  /// Shows a standard OS-level local notification on the device.
  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription:
          'This channel is used for important notifications that pop up on screen.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.toSigned(53),
      title,
      body,
      platformDetails,
    );
  }
}
