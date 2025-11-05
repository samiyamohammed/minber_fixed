// lib/main.dart (FINAL STABLE VERSION)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:logger/logger.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:minber/services/adhan_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

// --- Your other project imports ---
import 'dart:async';
import 'package:minber/screens/about_us_page.dart';
import 'package:minber/screens/coming_soon_page.dart';
import 'package:minber/screens/help_and_support_page.dart';
import 'package:minber/screens/media/media_hub_screen.dart';
import 'package:minber/screens/news_see_all_page.dart';
import 'package:minber/screens/notification_settings_page.dart';
import 'package:minber/screens/update_profile_page.dart';
import 'package:minber/widgets/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'services/firebase-notification.dart';
import 'widgets/in_app_notification_banner.dart';
import 'providers/user_provider.dart';
import 'providers/prayer_provider.dart';
import 'providers/notification_provider.dart';
import 'core/app_colors.dart';
import 'core/theme_notifier.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/Profile & Settings.dart';
import 'screens/change_password.dart';
import 'screens/live_screen.dart';
import 'screens/youtubechannel.dart';
import 'screens/ondemand.dart';
import 'screens/prayertime.dart';
import 'screens/hijri_calendar.dart';
import 'screens/qibla_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/upgrade_plan.dart';
import 'screens/manage_subscriptions.dart';
import 'screens/subapps_screen.dart';
import 'screens/dua_dhikr_page.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'services/api_service.dart';
import 'firebase_options.dart';

// --- SHARED TOP-LEVEL OBJECTS AND CALLBACKS ---
final logger = Logger();
final audioPlayer = AudioPlayer();
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

/// This shared function initializes all notification-related plugins.
Future<void> initializeNotifications() async {
  tz.initializeTimeZones();
  try {
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  } catch (e) {
    logger.e("Error getting local timezone: $e");
  }

  const android = AndroidInitializationSettings('@drawable/notification_icon');
  const settings = InitializationSettings(android: android);
  await flutterLocalNotificationsPlugin.initialize(settings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground);

  final androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  const AndroidNotificationChannel adhanChannel = AndroidNotificationChannel(
    'adhan_channel',
    'Adhan Notifications',
    description: 'Plays the full Adhan for prayer times.',
    importance: Importance.max,
    playSound: false,
  );
  await androidImplementation?.createNotificationChannel(adhanChannel);

  const AndroidNotificationChannel weeklyChannel = AndroidNotificationChannel(
    'weekly_channel',
    'Weekly Notifications',
    description: 'Reminder for Salawat Askār.',
    importance: Importance.max,
  );
  await androidImplementation?.createNotificationChannel(weeklyChannel);
}

/// The function that the AlarmManager will call when a prayer time is reached.
@pragma('vm:entry-point')
void fireAdhanAlarm(int id, Map<String, dynamic> params) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAdhanService();

  final logger = Logger();
  final prayerName = params['prayerName'] ?? 'Prayer Time';
  logger.i("⏰ ALARM FIRED for $prayerName. Starting Adhan background service.");

  final service = FlutterBackgroundService();
  final isRunning = await service.startService();
  if (isRunning) {
    service.invoke('startAdhan', {'prayerName': prayerName});
  } else {
    logger.e("Failed to start the background service.");
  }
}

// /// This function handles taps or dismissals of our Adhan notification.
// @pragma('vm:entry-point')
// void notificationTapBackground(NotificationResponse notificationResponse) {
//   final payload = notificationResponse.payload;
//   if (payload != null && payload.startsWith('silence_')) {
//     final id = int.tryParse(payload.split('_')[1]);
//     logger.i(
//         "ACTION: Notification interaction for Adhan ID: $id. Stopping audio.");
//     audioPlayer.stop();
//     if (id != null) {
//       flutterLocalNotificationsPlugin.cancel(id);
//     }
//   } else if (payload == "salawat") {
//     // Handle other background taps if needed
//   }
// }

// --- Your other top-level functions (callbackDispatcher, _firebaseMessagingBackgroundHandler) ---
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("🌍 Native WorkManager task executing: $task");
    WidgetsFlutterBinding.ensureInitialized();
    await initializeNotifications(); // Use the shared initializer

    try {
      await NotificationService.scheduleDailyAndWeeklyNotifications();
      debugPrint("✅ Background prayer notification scheduling complete.");
      return Future.value(true);
    } catch (err) {
      debugPrint("❌ Error in background prayer task: $err");
      return Future.value(false);
    }
  });
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseNotificationService.init();
  debugPrint("📲 Handling a background Firebase message: ${message.messageId}");
  FirebaseNotificationService.showLocalNotification(
    title: message.data['title'] ?? 'New Message',
    body: message.data['body'] ?? 'You have a new message from Minber TV.',
  );
}

// --- UPDATED main() FUNCTION ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background systems
  if (Platform.isAndroid) {
    await AndroidAlarmManager.initialize();
  }
  await initializeAdhanService(); // For the Adhan player

  // ✅ RESTORED: Call the proper init functions for each service.
  await NotificationService.init();
  await FirebaseNotificationService.init();

  // The rest of your main function is correct
  final savedThemeMode = await loadThemePreference();
  themeNotifier = ValueNotifier<ThemeMode>(savedThemeMode);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("🔥 FATAL: Firebase Core initialization failed: $e");
  }

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await Workmanager().registerPeriodicTask(
    "1",
    "dailyPrayerNotificationScheduler",
    frequency: const Duration(hours: 24),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  NotificationService.scheduleDailyAndWeeklyNotifications();
  setupFirebasePushNotifications();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final seenOnboarding = prefs.getBool('onboarding_complete') ?? false;

  String initialRoute = '/onboarding';
  if (isLoggedIn) {
    initialRoute = '/home';
  } else if (seenOnboarding) {
    initialRoute = '/login';
  }

  debugPrint('➡️ App Start → navigating to $initialRoute');
  runApp(MyApp(initialRoute: initialRoute));
}

// --- The rest of your file (setupFirebasePushNotifications, MyApp, etc.) is unchanged ---
// ...
// --- FIREBASE PUSH NOTIFICATION SETUP (UPDATED & CORRECTED) ---
Future<void> setupFirebasePushNotifications() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('🚫 Firebase Messaging permission denied.');
      return;
    }
    debugPrint('✅ Firebase Messaging permission granted.');

    await messaging.subscribeToTopic('all');
    debugPrint("📢 Subscribed to Firebase topic: all");

    final token = await messaging.getToken();
    debugPrint('🔥 Initial FCM Device Token: $token');

    FirebaseMessaging.instance.onTokenRefresh.listen((newFcmToken) async {
      debugPrint('🔄 FCM Token has been refreshed. New token: $newFcmToken');
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      if (accessToken != null) {
        debugPrint('User is logged in. Updating refreshed token on server...');
        await ApiService.updateFcmToken(newFcmToken, accessToken);
      } else {
        debugPrint('User is not logged in. No need to update token on server.');
      }
    }).onError((err) {
      debugPrint("❌ Error in onTokenRefresh listener: $err");
    });

    // --- ✅ FIX 1: The provider refresh logic is now correctly INSIDE the listener ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          "💬 Firebase foreground message received: ${message.notification?.title}");
      String title = message.notification?.title ??
          message.data['title'] ??
          "New Notification";
      String body = message.notification?.body ?? message.data['body'] ?? "";

      // Show the new, custom, animated banner from the top
      showOverlayNotification(title: title, body: body);

      // Trigger a live refresh for the badge count
      final context = NotificationService.navigatorKey.currentContext;
      if (context != null) {
        final provider =
            Provider.of<NotificationProvider>(context, listen: false);
        provider.fetchNotifications();
        debugPrint("🔄 Triggered live refresh of notifications provider.");
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          '🚀 App opened from Firebase notification: ${message.notification?.title}');
      NotificationService.navigatorKey.currentState
          ?.pushNamed('/notifications');
    });
  } catch (e) {
    debugPrint("❌ ERROR setting up Firebase Push Notifications: $e");
  }
}

// --- MAIN APP WIDGET (UPDATED & CORRECTED) ---
class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => PrayerProvider()),
        // ✅ FIX 2: Correctly initialize the NotificationProvider.
        // It now loads its own saved data when created.
        ChangeNotifierProvider(
          create: (context) => NotificationProvider()..init(),
        ),
        ProxyProvider<UserProvider, ApiClient>(
          update: (context, userProvider, previousApiClient) =>
              ApiClient(userProvider),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, ThemeMode currentMode, __) {
          return MaterialApp(
            navigatorKey: NotificationService.navigatorKey,
            navigatorObservers: [routeObserver],
            debugShowCheckedModeBanner: false,
            title: 'Minber TV',
            theme: ThemeData(
              primaryColor: AppColors.primaryBlue,
              scaffoldBackgroundColor: AppColors.backgroundLight,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.backgroundLight,
                foregroundColor: AppColors.primaryBlue,
                elevation: 0.0,
                scrolledUnderElevation: 1.0,
                titleTextStyle: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                iconTheme: IconThemeData(color: AppColors.primaryBlue),
              ),
              brightness: Brightness.light,
              colorScheme: const ColorScheme.light(
                primary: AppColors.primaryBlue,
                secondary: AppColors.accentBlue,
                surface: AppColors.backgroundLight,
                onBackground: AppColors.textGrey,
                onSurface: AppColors.textGrey,
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Color.fromARGB(255, 61, 61, 61)),
                bodyMedium: TextStyle(color: Colors.black54),
              ),
            ),
            darkTheme: ThemeData(
              primaryColor: const Color.fromARGB(255, 27, 127, 209),
              scaffoldBackgroundColor: AppColors.backgroundDark,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.surfaceDark,
                foregroundColor: Colors.white,
                elevation: 2.0,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                iconTheme: IconThemeData(color: Colors.white70),
              ),
              brightness: Brightness.dark,
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primaryBlue,
                secondary: AppColors.accentBlue,
                surface: AppColors.surfaceDark,
                onBackground: Colors.white70,
                onSurface: Colors.white70,
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white70),
                bodyMedium: TextStyle(color: Colors.white54),
              ),
            ),
            themeMode: currentMode,
            initialRoute: initialRoute,
            routes: {
              '/onboarding': (_) => const OnboardingScreen(),
              '/home': (_) => const HomeScreen(),
              '/login': (_) => const LoginPage(),
              '/signup': (_) => const SignUpPage(),
              '/profile': (_) => const ProfilePage(),
              '/forgot-password': (_) => const ForgotPasswordScreen(),
              '/reset-password': (_) => const ResetPasswordScreen(),
              '/changePassword': (_) => const ChangePasswordPage(),
              '/live': (_) => const LiveStreamPage(),
              '/media': (_) => const MediaHubScreen(),
              '/news': (context) {
                final args = ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
                return NewsSeeAllPage(
                  newsArticles: args['newsArticles'] as List<dynamic>,
                  apiBaseUrl: args['apiBaseUrl'] as String,
                );
              },
              '/youtubeContent': (_) => const OnDemandPage(),
              '/channel': (_) => const YouTubeChannelDetailPage(),
              '/ondemand': (_) => const OnDemandPage(),
              '/prayer': (_) => const PrayerTimesPage(),
              '/hijri-calendar': (_) => const HijriCalendarPage(),
              '/qibla-compass': (_) => const QiblaCompassPage(),
              '/chatbot': (_) => const ChatBotPage(),
              '/notifications': (_) => const NotificationsPage(),
              '/subscription': (_) => const SubscriptionPage(),
              '/upgradeplan': (_) => const UpgradePlanPage(),
              '/subapps': (_) => const KiriyogdeyraPage(),
              '/dua-dhikr': (_) => const DuaDhikrPage(),
              '/notification-settings': (_) => const NotificationSettingsPage(),
              '/about-us': (_) => const AboutUsPage(),
              '/help-and-support': (_) => const HelpAndSupportPage(),
              '/coming-soon': (_) => const ComingSoonPage(),
              '/update-profile': (_) => const UpdateProfilePage(),
            },
          );
        },
      ),
    );
  }
}
