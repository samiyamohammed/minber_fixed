import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// This function MUST be a top-level function (not inside a class)
// to be used as the background message handler.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to initialize other services here, like Firebase core, you can.
  // await Firebase.initializeApp(); // This is often needed.
  debugPrint("📲 Handling a background message: ${message.messageId}");
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request permission from the user (for iOS and modern Android)
    await _firebaseMessaging.requestPermission();

    // Fetch the FCM token for this device
    final fcmToken = await _firebaseMessaging.getToken();
    debugPrint("📱 FCM Token: $fcmToken");

    // Set up the background message handler.
    // This is the line that was likely causing the crash.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
