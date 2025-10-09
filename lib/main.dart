import 'dart:async';
import 'package:flutter/material.dart';
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
import 'core/app_colors.dart';

// --- SCREEN IMPORTS ---
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/Profile & Settings.dart';
import 'screens/edit_profile.dart';
import 'screens/change_password.dart';
import 'screens/live_screen.dart';
import 'screens/media.dart';
import 'screens/youtube_screen.dart';
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

// --- THEME HANDLING ---
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> saveThemePreference(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('themeMode', mode.index);
}

Future<void> loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('themeMode') ?? ThemeMode.system.index;
  themeNotifier.value = ThemeMode.values[themeIndex];
}

// --- BACKGROUND TASK DEFINITION (FOR LOCAL PRAYER NOTIFICATIONS) ---
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

//
// --- ▼▼▼▼ CRITICAL FIX IS HERE ▼▼▼▼ ---
//
// --- CORRECTED FIREBASE BACKGROUND HANDLER ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1. Initialize Firebase
  await Firebase.initializeApp();
  // 2. Initialize our notification service so we can show a notification
  await FirebaseNotificationService.init();

  debugPrint("📲 Handling a background Firebase message: ${message.messageId}");

  // 3. Create and display a local notification using the message data
  //    **CRUCIAL ASSUMPTION:** Your backend must send 'title' and 'body'
  //    inside the 'data' payload of the push notification.
  FirebaseNotificationService.showLocalNotification(
    title: message.data['title'] ?? 'New Message',
    body: message.data['body'] ?? 'You have a new message from Minber TV.',
  );
}
// --- ▲▲▲▲ END OF CRITICAL FIX ▲▲▲▲ ---

// --- MAIN FUNCTION ---
Future<void> main() async {
  // STAGE 1: CORE INITIALIZATION
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase Core initialized successfully.");
  } catch (e) {
    debugPrint("🔥 FATAL: Firebase Core initialization failed: $e");
  }

  // STAGE 2: REGISTER ALL BACKGROUND HANDLERS
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  await Workmanager().registerPeriodicTask(
    "1",
    "dailyPrayerNotificationScheduler",
    frequency: const Duration(hours: 24),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  // STAGE 3: INITIALIZE FOREGROUND SERVICES & PREFERENCES
  final prefs = await SharedPreferences.getInstance();
  await loadThemePreference();
  await NotificationService.init();
  await FirebaseNotificationService.init();

  // STAGE 4: TRIGGER ASYNCHRONOUS SETUPS (FIRE-AND-FORGET)
  NotificationService.scheduleDailyAndWeeklyNotifications();
  setupFirebasePushNotifications();

  // STAGE 5: DETERMINE INITIAL ROUTE AND RUN APP
  final accessToken = prefs.getString('accessToken');
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final seenOnboarding = prefs.getBool('onboarding_complete') ?? false;

  String initialRoute;
  if (isLoggedIn && accessToken != null && accessToken.isNotEmpty) {
    initialRoute = '/home';
  } else if (seenOnboarding) {
    initialRoute = '/login';
  } else {
    initialRoute = '/onboarding';
  }

  debugPrint('➡️ App Start → navigating to $initialRoute');
  runApp(MyApp(initialRoute: initialRoute));
}

/// A single, clean function to set up all Firebase Push Notification logic.
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

    // This handles messages that arrive while the app is OPEN (in the foreground).
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        "💬 Firebase foreground message received: ${message.notification?.title}",
      );

      // We check BOTH the `notification` and `data` payloads.
      String title = message.notification?.title ??
          message.data['title'] ??
          "New Notification";
      String body = message.notification?.body ?? message.data['body'] ?? "";

      FirebaseNotificationService.showLocalNotification(
        title: title,
        body: body,
      );
    });

    // This handles when the user TAPS a notification to open the app.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '🚀 App opened from Firebase notification: ${message.notification?.title}',
      );
      final navigator = NotificationService.navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamed('/notifications');
      }
    });
  } catch (e) {
    debugPrint("❌ ERROR setting up Firebase Push Notifications: $e");
  }
}

// --- MAIN APP WIDGET ---
class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, ThemeMode currentMode, __) {
          return MaterialApp(
            navigatorKey: NotificationService.navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Minber TV',
            theme: ThemeData(
              primaryColor: AppColors.primary,
              scaffoldBackgroundColor: AppColors.background,
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              brightness: Brightness.light,
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                secondary: Colors.tealAccent,
                surface: Colors.white,
                onBackground: Colors.black87,
                onSurface: Colors.black87,
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black87),
                bodyMedium: TextStyle(color: Colors.black87),
              ),
            ),
            darkTheme: ThemeData(
              primaryColor: AppColors.primary,
              scaffoldBackgroundColor: const Color(0xFF121212),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1F1F1F),
                foregroundColor: Colors.white,
                elevation: 0,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: IconThemeData(color: Colors.white70),
              ),
              brightness: Brightness.dark,
              colorScheme: ColorScheme.dark(
                primary: AppColors.primary,
                secondary: Colors.tealAccent,
                surface: const Color(0xFF1F1F1F),
                onBackground: Colors.white70,
                onSurface: Colors.white70,
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white70),
                bodyMedium: TextStyle(color: Colors.white70),
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
              // '/editProfile': (_) => const EditProfilePage(),
              '/changePassword': (_) => const ChangePasswordPage(),
              '/live': (_) => const LiveStreamPage(),
              '/media': (_) => const MediaHubPage(),
              '/youtube': (_) => const YouTubePage(),
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
            },
          );
        },
      ),
    );
  }
}
