// lib/main.dart (FINAL STABLE VERSION WITH GUEST PERSISTENCE FIX)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:logger/logger.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
import 'providers/notification_settings_provider.dart';
import 'screens/permission_screen.dart';
// import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

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

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  final logger = Logger();
  // This is the handler for the Adhan notification's "Silence" button
  if (notificationResponse.actionId == 'silence_action') {
    logger.i(
        "ACTION: 'Silence' button tapped in background. Invoking stopService.");
    FlutterBackgroundService().invoke('stopService');
  }
  // This handles taps on the weekly Salawat notification
  else if (notificationResponse.payload == "salawat") {
    logger.i("ACTION: Salawat notification tapped in background.");
    // Note: Navigation from here is not reliable. Tapping the notification
    // should bring the app to the foreground, where onMessageOpenedApp handles navigation.
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("WorkManager: Task executing ($task)");
    // We will create this function in the next step.
    // This is the new brain of our scheduling.
    await NotificationService.scheduleDailyAndWeeklyNotifications();
    debugPrint("WorkManager: Task completed.");
    return Future.value(true);
  });
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Standard initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseNotificationService.init();
  logger.i("📲 Handling a background Firebase message: ${message.messageId}");

  final notificationId = message.data['id']?.toString();

  // --- 🔥 THE CORE FIX: MANIPULATE STORED STATE DIRECTLY ---
  // If a notification arrives with an ID, we assume it's new or re-triggered,
  // and we must ensure it is not marked as 'read'.
  if (notificationId != null) {
    logger.i("Background Push for ID: $notificationId. Ensuring it's unread.");
    try {
      // Directly access the device's storage from the background.
      final prefs = await SharedPreferences.getInstance();

      // Use the EXACT same key the NotificationProvider uses.
      const key = 'read_notifications_set';

      // Load the list of read IDs that are currently saved.
      final List<String> readIds = prefs.getStringList(key) ?? [];

      // If the ID of the incoming notification was in the list, remove it.
      if (readIds.contains(notificationId)) {
        readIds.remove(notificationId);
        // Save the modified list back to storage.
        await prefs.setStringList(key, readIds);
        logger.i(
            "✅ State Fixed: Removed '$notificationId' from read list in background.");
      } else {
        logger.i(
            "'$notificationId' was not in the read list. No state change needed.");
      }
    } catch (e) {
      logger.e("❌ Error updating read status in background: $e");
    }
  }

  // Finally, show the local notification to the user as before.
  FirebaseNotificationService.showLocalNotification(
    title: message.data['title'] ?? 'New Message',
    body: message.data['body'] ?? 'You have a new message from Minber TV.',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await initializeAdhanService();
  await NotificationService.init();
  await FirebaseNotificationService.init();

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

  // Initialize Android Alarm Manager
  // await AndroidAlarmManager.initialize();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await Workmanager().registerPeriodicTask(
    "prayer_notification_scheduler",
    "schedulePrayerNotifications",
    frequency: const Duration(hours: 12),
    initialDelay:
        const Duration(minutes: 10), // We can make this delay longer now
    constraints: Constraints(
      networkType: NetworkType.notRequired,
    ),
  );

  // --- ✅ ADD THIS BACK IN FOR IMMEDIATE SCHEDULING ---
  // This will run ONCE every time the user opens the app, ensuring
  // the schedule is always fresh. WorkManager is the long-term backup.
  NotificationService.scheduleDailyAndWeeklyNotifications();

  setupFirebasePushNotifications();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  // --- 👇 FIX: CHECK FOR GUEST FLAG HERE 👇 ---
  final isGuest = prefs.getBool('isGuest') ?? false;
  final seenOnboarding = prefs.getBool('onboarding_complete') ?? false;

  String initialRoute = '/onboarding';

  // Update logic: If logged in OR is a guest, go to Home
  if (isLoggedIn || isGuest) {
    initialRoute = '/home';
  } else if (seenOnboarding) {
    initialRoute = '/login';
  }

  debugPrint(
      '➡️ App Start → navigating to $initialRoute (LoggedIn: $isLoggedIn, Guest: $isGuest)');
  runApp(MyApp(initialRoute: initialRoute));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // NotificationService.debugNotificationSetup();
  });
}

// --- CHAIN OF EVIDENCE: STEP 1 ---
Future<void> setupFirebasePushNotifications() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.subscribeToTopic('all');

    FirebaseMessaging.instance.onTokenRefresh.listen((newFcmToken) async {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      if (accessToken != null) {
        await ApiService.updateFcmToken(newFcmToken, accessToken);
      } else {
        // Optional: If you want to keep guest tokens updated on refresh
        // await ApiService.registerGuestFcmToken(newFcmToken);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.i("--- [PUSH NOTIFICATION RECEIVED IN FOREGROUND] ---");
      logger.d("RAW PAYLOAD: ${message.data}");

      final title = message.data['title'] ??
          message.notification?.title ??
          "New Notification";
      final body = message.data['body'] ?? message.notification?.body ?? "";
      showOverlayNotification(title: title, body: body);

      final context = NotificationService.navigatorKey.currentContext;
      if (context == null) {
        logger.e("❌ CONTEXT IS NULL. Cannot update provider.");
        return;
      }

      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      final String? notificationId = message.data['id']?.toString();

      // --- ✅ THIS IS THE CORE CHANGE ---
      // Replace the old logic with a call to our new, robust method.
      if (notificationId != null) {
        provider.markAsUnreadAndRefresh(notificationId);
      } else {
        // Fallback remains the same if there's no ID.
        logger.w("⚠️ ID missing in payload. Falling back to full refresh.");
        provider.fetchNotifications();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.i("🚀 App opened from a tapped notification.");
      NotificationService.navigatorKey.currentState
          ?.pushNamed('/notifications');
    });
  } catch (e) {
    logger.f("❌ FATAL ERROR setting up Firebase Push Notifications: $e");
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
        ChangeNotifierProvider(
          create: (context) => NotificationProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationSettingsProvider(),
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
              '/permission': (_) => const PermissionScreen(),
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
