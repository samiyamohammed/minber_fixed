// lib/main.dart (FINAL STABLE VERSION FOR PRODUCTION WITH AUTO-UPDATE)

import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:logger/logger.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:minber/providers/ramadan_provider.dart';
import 'package:minber/screens/ramadan_quiz_screen.dart';
import 'package:minber/services/adhan_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

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
import 'services/web_prayer_notification_service.dart';
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
import 'config/fcm_web_config.dart';
import 'providers/notification_settings_provider.dart';
import 'screens/permission_screen.dart';

// AUTO-UPDATE IMPORTS
import 'services/versioning_service.dart';
import 'widgets/update_dialog.dart';

final logger = Logger();
final audioPlayer = AudioPlayer();
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  if (notificationResponse.actionId == 'silence_action') {
    FlutterBackgroundService().invoke('stopService');
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // ESSENTIAL PRODUCTION FIX: Required for background isolates to use plugins
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    debugPrint("WorkManager: Task executing ($task)");
    try {
      // Sync names with task registration for Production reliability (Matches Al Faruk logic)
      if (task.contains("schedulePrayerNotifications") ||
          task.contains("prayer_notification_scheduler")) {
        await NotificationService.init();
        await NotificationService.scheduleDailyAndWeeklyNotifications();
      }
      return Future.value(true);
    } catch (err) {
      debugPrint("WorkManager Error: $err");
      return Future.value(false);
    }
  });
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseNotificationService.init();
  final notificationId = message.data['id']?.toString();
  if (notificationId != null) {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'read_notifications_set';
      final List<String> readIds = prefs.getStringList(key) ?? [];
      if (readIds.contains(notificationId)) {
        readIds.remove(notificationId);
        await prefs.setStringList(key, readIds);
      }
    } catch (e) {}
  }
  FirebaseNotificationService.showLocalNotification(
    title: message.data['title'] ?? 'New Message',
    body: message.data['body'] ?? 'You have a new message from Minber TV.',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await NotificationService.init();
    await FirebaseNotificationService.init();
  }

  final savedThemeMode = await loadThemePreference();
  themeNotifier = ValueNotifier<ThemeMode>(savedThemeMode);

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  } catch (e) {
    debugPrint("🔥 Firebase Init failed: $e");
  }

  if (!kIsWeb) {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      "prayer_notification_scheduler",
      "schedulePrayerNotifications",
      frequency: const Duration(hours: 12),
      initialDelay: const Duration(minutes: 5),
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
    NotificationService.scheduleDailyAndWeeklyNotifications();
  }

  setupFirebasePushNotifications();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final isGuest = prefs.getBool('isGuest') ?? false;
  final seenOnboarding = prefs.getBool('onboarding_complete') ?? false;

  if (kIsWeb) {
    final lat = prefs.getDouble('last_known_lat');
    final lng = prefs.getDouble('last_known_lng');
    if (lat != null && lng != null) {
      WebPrayerNotificationService.scheduleDailyAndWeeklyNotifications(
        latitude: lat,
        longitude: lng,
      );
    }
  }

  String initialRoute = '/onboarding';
  if (isLoggedIn || isGuest) {
    initialRoute = '/home';
  } else if (seenOnboarding) {
    initialRoute = '/login';
  }

  debugPrint('➡️ App Start → navigating to $initialRoute');
  runApp(MyApp(initialRoute: initialRoute));
}

Future<void> setupFirebasePushNotifications() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.subscribeToTopic('all');

    if (kIsWeb && FcmWebConfig.isConfigured) {
      final webToken = await messaging.getToken(
        vapidKey: FcmWebConfig.vapidKey,
      );
      if (webToken != null) {
        debugPrint('✅ Web FCM token obtained');
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('accessToken');
        if (accessToken != null) {
          await ApiService.updateFcmToken(webToken, accessToken);
        } else {
          await ApiService.registerGuestFcmToken(webToken);
        }
      }
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newFcmToken) async {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      if (accessToken != null) {
        await ApiService.updateFcmToken(newFcmToken, accessToken);
      } else if (kIsWeb) {
        await ApiService.registerGuestFcmToken(newFcmToken);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.data['title'] ??
          message.notification?.title ??
          "New Notification";
      final body = message.data['body'] ?? message.notification?.body ?? "";
      showOverlayNotification(title: title, body: body);

      final context = NotificationService.navigatorKey.currentContext;
      if (context != null) {
        final provider =
            Provider.of<NotificationProvider>(context, listen: false);
        final String? notificationId = message.data['id']?.toString();
        if (notificationId != null) {
          provider.markAsUnreadAndRefresh(notificationId);
        } else {
          provider.fetchNotifications();
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      NotificationService.navigatorKey.currentState
          ?.pushNamed('/notifications');
    });
  } catch (e) {
    logger.f("❌ ERROR setting up Push Notifications: $e");
  }
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Logic: Trigger version check after the build is completed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdate();
    });
  }

  Future<void> _checkUpdate() async {
    // 1. We now call 'checkVersionStatus' which returns an object with all the data
    final result = await VersioningService.checkVersionStatus();

    debugPrint(
        "🔍 Version Check: Store (${result.storeVersion}) vs Local (${result.localVersion})");

    if (result.canUpdate && mounted) {
      showDialog(
        context: NotificationService.navigatorKey.currentContext ?? context,
        barrierDismissible: true,
        builder: (context) => UpdateDialog(
          // 2. We pass the version numbers found by the scraper to the dialog
          localVersion: result.localVersion,
          storeVersion: result.storeVersion,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => PrayerProvider()),
        ChangeNotifierProvider(
            create: (context) => NotificationProvider()..init()),
        ChangeNotifierProvider(
            create: (context) => NotificationSettingsProvider()),
        ProxyProvider<UserProvider, ApiClient>(
          update: (context, userProvider, previousApiClient) =>
              ApiClient(userProvider),
        ),
        ChangeNotifierProxyProvider<ApiClient, RamadanProvider>(
          create: (context) =>
              RamadanProvider(Provider.of<ApiClient>(context, listen: false)),
          update: (context, apiClient, previous) =>
              previous ?? RamadanProvider(apiClient),
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
            themeMode: currentMode,
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
                    fontWeight: FontWeight.w600),
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
                    fontWeight: FontWeight.w600),
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
            initialRoute: widget.initialRoute,
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
                    apiBaseUrl: args['apiBaseUrl'] as String);
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
              '/ramadan-quiz': (_) => const RamadanQuizScreen(),
            },
          );
        },
      ),
    );
  }
}
