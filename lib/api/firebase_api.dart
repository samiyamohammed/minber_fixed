// import 'package:firebase_messaging/firebase_messaging.dart';

// class FirebaseApi {
//   final _firebaseMessaging = FirebaseMessaging.instance;

//   Future<void> initNotifications() async {
//     await _firebaseMessaging.requestPermission();
//     final fcmToken = await _firebaseMessaging.getToken();
//     print('Token: $fcmToken');
//   }
// }
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    final settings = await _firebaseMessaging.requestPermission();
    print('Permission status: ${settings.authorizationStatus}');
    try {
      final fcmToken = await _firebaseMessaging.getToken();
      print('Token: $fcmToken');
      FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
      if (fcmToken == null) {
        print(
          'FCM token is null. Permission may be denied or device not supported.',
        );
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('Handling background message: ${message.data}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
  }
}
