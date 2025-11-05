// lib/services/adhan_background_service.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// This function runs when the user interacts with the notification (e.g., taps the Silence button)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  if (notificationResponse.actionId == 'silence_action') {
    logger.i("ACTION: 'Silence' button tapped. Invoking stopService.");
    FlutterBackgroundService().invoke('stopService');
  }
}

// This is the main entry point for the background service
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final audioPlayer = AudioPlayer();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  logger.i("🎧 Adhan Background Service has started.");

  // Listen for the 'startAdhan' command from the alarm callback
  service.on('startAdhan').listen((event) async {
    final prayerName = event?['prayerName'] ?? 'Prayer Time';
    logger.i("▶️ Received 'startAdhan' command for $prayerName");

    // Show the persistent notification with the Silence button.
    await flutterLocalNotificationsPlugin.show(
      888,
      '$prayerName Adhan',
      'The call to prayer has begun.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'adhan_channel',
          'Adhan Notifications',
          channelDescription: 'Plays the full Adhan for prayer times',
          importance: Importance.max,
          priority: Priority.high,
          playSound: false,
          icon: '@drawable/notification_icon',
          ongoing: true,
          autoCancel: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'silence_action', // A unique ID for the action
              'Silence', // The text on the button
            ),
          ],
        ),
      ),
    );

    try {
      // Set audio context before playing
      await audioPlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ));
      await audioPlayer.release(); // Reset the player
      await audioPlayer.play(AssetSource('sounds/adhan.mp3'));
      logger.i("🎵 Adhan audio is now playing.");
    } catch (e) {
      logger.e("❌ CRITICAL: Error playing Adhan audio: $e");
      service.invoke('stopService');
    }
  });

  // Listen for the command to stop everything
  service.on('stopService').listen((event) async {
    logger.w("⏹️ Received 'stopService' command. Stopping Adhan.");
    try {
      await audioPlayer.stop();
      await flutterLocalNotificationsPlugin.cancel(888);
      service.stopSelf();
      logger.i("✅ Service and audio stopped successfully.");
    } catch (e) {
      logger.e("❌ Error stopping service: $e");
    }
  });

  // Automatically stop the service when the Adhan finishes playing
  audioPlayer.onPlayerComplete.listen((event) {
    logger.i("🎶 Adhan audio completed naturally.");
    service.invoke('stopService');
  });
}

// This function initializes the service and its notification channel.
Future<void> initializeAdhanService() async {
  final service = FlutterBackgroundService();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel adhanChannel = AndroidNotificationChannel(
    'adhan_channel',
    'Adhan Notifications',
    description: 'Plays the full Adhan for prayer times',
    importance: Importance.max,
    playSound: false,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(adhanChannel);

  // Initialize the plugin and link the notification tap handler
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/notification_icon'),
    ),
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // Configure the service itself
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      notificationChannelId: 'adhan_channel',
      initialNotificationTitle: 'Adhan Service',
      initialNotificationContent: 'Ready for prayer times',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
  );
}
