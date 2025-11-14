// // lib/services/adhan_background_service.dart (FINAL - SYNTAX FIXED)

// import 'dart:async';
// import 'dart:ui';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:logger/logger.dart';

// final logger = Logger();
// final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// @pragma('vm:entry-point')
// Future<void> onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   final audioPlayer = AudioPlayer();
//   logger.i("🎧 Adhan Background Service has started silently.");

//   // The service now runs truly in the background without any initial notification.
//   // We only show a notification when the Adhan actually needs to play.

//   service.on('startAdhan').listen((event) async {
//     final prayerName = event?['prayerName'] ?? 'Prayer Time';
//     logger.i("▶️ Received 'startAdhan' command for $prayerName");

//     await flutterLocalNotificationsPlugin.show(
//       999, // A unique ID for the Adhan notification
//       '$prayerName Adhan',
//       'The call to prayer has begun.',
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'adhan_channel', // The main, high-importance channel
//           'Adhan Notifications',
//           channelDescription: 'Plays the full Adhan for prayer times',
//           importance: Importance.max,
//           priority: Priority.high,
//           playSound: false,
//           icon: '@drawable/notification_icon',
//           ongoing: true,
//           autoCancel: false,
//           actions: <AndroidNotificationAction>[
//             AndroidNotificationAction('silence_action', 'Silence'),
//           ],
//         ),
//       ),
//     );

//     try {
//       await audioPlayer.setAudioContext(AudioContext(
//         android: AudioContextAndroid(
//           isSpeakerphoneOn: true,
//           stayAwake: true,
//           contentType: AndroidContentType.sonification,
//           usageType: AndroidUsageType.alarm,
//           audioFocus: AndroidAudioFocus.gain,
//         ),
//       ));
//       await audioPlayer.release();
//       await audioPlayer.play(AssetSource('sounds/adhan.mp3'));
//       logger.i("🎵 Adhan audio is now playing.");
//     } catch (e) {
//       logger.e("❌ CRITICAL: Error playing Adhan audio: $e");
//       service.invoke('stopService');
//     }
//   });

//   service.on('stopService').listen((event) async {
//     logger.w("⏹️ Received 'stopService' command. Stopping Adhan.");
//     try {
//       await audioPlayer.stop();
//       await flutterLocalNotificationsPlugin.cancel(999);
//       service.stopSelf();
//       logger.i("✅ Service and audio stopped successfully.");
//     } catch (e) {
//       logger.e("❌ Error stopping service: $e");
//     }
//   });

//   audioPlayer.onPlayerComplete.listen((event) {
//     logger.i("🎶 Adhan audio completed naturally.");
//     service.invoke('stopService');
//   });
// }

// Future<void> initializeAdhanService() async {
//   final service = FlutterBackgroundService();

//   // Create the channel for the audible Adhan alerts.
//   const AndroidNotificationChannel adhanChannel = AndroidNotificationChannel(
//     'adhan_channel',
//     'Adhan Notifications',
//     description: 'Plays the full Adhan for prayer times',
//     importance: Importance.max,
//     playSound: false,
//   );

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(adhanChannel);

//   // ✅ --- THIS IS THE CORRECTED CONFIGURATION BLOCK --- ✅
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       // This is the key parameter that tells the service to be a foreground
//       // service without showing an initial notification. It stops the crash silently.
//       isForegroundMode: true,
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: false,
//     ),
//   ); // <-- The missing parenthesis was here.
// }
