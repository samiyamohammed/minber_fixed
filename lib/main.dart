// lib/main.dart (Fully Updated & Ready to Paste)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:minber_super_app_new_fixed/screens/YouTube_screen.dart';
import 'package:minber_super_app_new_fixed/screens/about_us_page.dart';
import 'package:minber_super_app_new_fixed/screens/coming_soon_page.dart';
import 'package:minber_super_app_new_fixed/screens/help_and_support_page.dart';
import 'package:minber_super_app_new_fixed/screens/notification_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:provider/provider.dart';

// --- SERVICE IMPORTS ---
import 'services/notification_service.dart'; // For LOCAL prayer notifications
import 'services/firebase-notification.dart'; // For FIREBASE push notifications

// --- PROVIDER & CORE IMPORTS ---
import 'providers/user_provider.dart';
import 'providers/prayer_provider.dart';
import 'core/app_colors.dart';
import 'core/theme_notifier.dart';

// --- SCREEN IMPORTS ---
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/Profile & Settings.dart';
// import 'screens/edit_profile.dart';
import 'screens/change_password.dart';
import 'screens/live_screen.dart';
import 'screens/media.dart';
import 'screens/youtube_screen.dart' hide YouTubePage;
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
import 'package:video_player/video_player.dart';

// --- BACKGROUND TASK DEFINITION (UNCHANGED) ---
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("🌍 Native WorkManager task executing: $task");
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.init();

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

// --- FIREBASE BACKGROUND HANDLER (UNCHANGED) ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await FirebaseNotificationService.init();
  debugPrint("📲 Handling a background Firebase message: ${message.messageId}");
  FirebaseNotificationService.showLocalNotification(
    title: message.data['title'] ?? 'New Message',
    body: message.data['body'] ?? 'You have a new message from Minber TV.',
  );
}

// --- MAIN FUNCTION (UNCHANGED) ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Removed as the package does not exist

  final savedThemeMode = await loadThemePreference();
  themeNotifier = ValueNotifier<ThemeMode>(savedThemeMode);

  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase Core initialized successfully.");
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

  final prefs = await SharedPreferences.getInstance();
  await NotificationService.init();
  await FirebaseNotificationService.init();

  NotificationService.scheduleDailyAndWeeklyNotifications();
  setupFirebasePushNotifications();

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

// --- FIREBASE PUSH NOTIFICATION SETUP (UNCHANGED) ---
Future<void> setupFirebasePushNotifications() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('🚫 Firebase Messaging permission denied.');
      return;
    }
    debugPrint('✅ Firebase Messaging permission granted.');

    final token = await messaging.getToken();
    debugPrint('🔥 FCM Device Token: $token');
    await messaging.subscribeToTopic('all');
    debugPrint("📢 Subscribed to Firebase topic: all");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          "💬 Firebase foreground message received: ${message.notification?.title}");
      String title = message.notification?.title ??
          message.data['title'] ??
          "New Notification";
      String body = message.notification?.body ?? message.data['body'] ?? "";
      FirebaseNotificationService.showLocalNotification(
          title: title, body: body);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          '🚀 App opened from Firebase notification: ${message.notification?.title}');
      final navigator = NotificationService.navigatorKey.currentState;
      navigator?.pushNamed('/notifications');
    });
  } catch (e) {
    debugPrint("❌ ERROR setting up Firebase Push Notifications: $e");
  }
}

// --- MAIN APP WIDGET (UPDATED) ---
class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => PrayerProvider()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, ThemeMode currentMode, __) {
          return MaterialApp(
            navigatorKey: NotificationService.navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Minber TV',

            // --- ✅ THEME UPDATED ---
            theme: ThemeData(
              primaryColor: AppColors.primaryBlue,
              scaffoldBackgroundColor: AppColors.backgroundLight,
              appBarTheme: const AppBarTheme(
                // Modern white AppBar with blue text/icons
                backgroundColor: AppColors.backgroundLight,
                foregroundColor: AppColors.primaryBlue,
                elevation: 0.0,
                scrolledUnderElevation: 1.0, // Subtle shadow on scroll
                titleTextStyle: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                iconTheme: IconThemeData(color: AppColors.primaryBlue),
              ),
              brightness: Brightness.light,
              colorScheme: const ColorScheme.light(
                primary: AppColors.primaryBlue, // Consistent primary blue
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

            // --- ✅ DARK THEME UPDATED ---
            darkTheme: ThemeData(
              primaryColor: AppColors.primaryBlue,
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
                primary: AppColors.primaryBlue, // Consistent primary blue
                secondary:
                    AppColors.accentBlue, // Kept accent for variety if needed
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
            // --- ROUTES (UNCHANGED) ---
            routes: {
              '/onboarding': (_) => const OnboardingScreen(),
              '/home': (_) => const HomeScreen(),
              '/login': (_) => const LoginPage(),
              '/signup': (_) => const SignUpPage(),
              '/profile': (_) => const ProfilePage(),
              // '/editProfile': (_) => const EditProfilePage(),
              '/forgot-password': (_) => const ForgotPasswordScreen(),
              '/reset-password': (_) => const ResetPasswordScreen(),
              '/changePassword': (_) => const ChangePasswordPage(),
              '/live': (_) => const LiveStreamPage(),
              '/media': (_) => const MediaHubPage(),
              // '/youtube': (_) => const YouTubePage(),
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
            },
          );
        },
      ),
    );
  }
}
