import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Import the primary NotificationService to use its navigatorKey
import 'package:minber_super_app_new_fixed/services/notification_service.dart';

class FirebaseNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // DO NOT define a new navigatorKey here. We will use the one from NotificationService.

  static Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@drawable/notification_icon');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _localNotifications.initialize(
      initSettings,
      // This function handles what happens when a user taps the notification
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Use the CENTRAL navigatorKey from NotificationService
        final navigator = NotificationService.navigatorKey.currentState;
        if (navigator != null) {
          // Navigate to the notifications screen
          navigator.pushNamed('/notifications');
        }
      },
    );
  }

  /// Shows a local notification on the device.
  /// This is used to display Firebase messages that arrive when the app is in the foreground.
  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'fcm_default_channel', // Use a unique channel ID for Firebase messages
      'General Notifications',
      channelDescription:
          'Channel for general app notifications from Firebase.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    // Show the notification
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.toSigned(53), // Unique ID
      title,
      body,
      platformDetails,
    );
  }
}
