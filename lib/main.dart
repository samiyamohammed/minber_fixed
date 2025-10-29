// // lib/main.dart (Fully Updated & Ready to Paste)

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:minber_super_app_new_fixed/screens/YouTube_screen.dart';
// import 'package:minber_super_app_new_fixed/screens/about_us_page.dart';
// import 'package:minber_super_app_new_fixed/screens/coming_soon_page.dart';
// import 'package:minber_super_app_new_fixed/screens/help_and_support_page.dart';
// import 'package:minber_super_app_new_fixed/screens/media/media_hub_screen.dart';
// import 'package:minber_super_app_new_fixed/screens/news_see_all_page.dart';
// import 'package:minber_super_app_new_fixed/screens/notification_settings_page.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:workmanager/workmanager.dart';
// import 'package:provider/provider.dart';

// // --- SERVICE IMPORTS ---
// import 'services/notification_service.dart'; // For LOCAL prayer notifications
// import 'services/firebase-notification.dart'; // For FIREBASE push notifications

// // --- PROVIDER & CORE IMPORTS ---
// import 'providers/user_provider.dart';
// import 'providers/prayer_provider.dart';
// import 'core/app_colors.dart';
// import 'core/theme_notifier.dart';

// // --- SCREEN IMPORTS ---
// import 'screens/onboarding_screen.dart';
// import 'screens/home_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/signup_screen.dart';
// import 'screens/Profile & Settings.dart';
// import 'screens/change_password.dart';
// import 'screens/live_screen.dart';
// import 'screens/youtubechannel.dart';
// import 'screens/ondemand.dart';
// import 'screens/prayertime.dart';
// import 'screens/hijri_calendar.dart';
// import 'screens/qibla_screen.dart';
// import 'screens/chatbot_screen.dart';
// import 'screens/notification_screen.dart';
// import 'screens/upgrade_plan.dart';
// import 'screens/manage_subscriptions.dart';
// import 'screens/subapps_screen.dart';
// import 'screens/dua_dhikr_page.dart';
// import 'screens/forgot_password_screen.dart';
// import 'screens/reset_password_screen.dart';
// import 'services/api_service.dart';
// import 'firebase_options.dart';

// // --- ✅ UPDATE 1: GLOBAL KEY FOR IN-APP NOTIFICATIONS ---
// // This key allows us to show a SnackBar from anywhere in the app.
// final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
//     GlobalKey<ScaffoldMessengerState>();

// // --- BACKGROUND TASK DEFINITION (UNCHANGED) ---
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     debugPrint("🌍 Native WorkManager task executing: $task");
//     WidgetsFlutterBinding.ensureInitialized();
//     await NotificationService.init();

//     try {
//       await NotificationService.scheduleDailyAndWeeklyNotifications();
//       debugPrint("✅ Background prayer notification scheduling complete.");
//       return Future.value(true);
//     } catch (err) {
//       debugPrint("❌ Error in background prayer task: $err");
//       return Future.value(false);
//     }
//   });
// }

// // --- FIREBASE BACKGROUND HANDLER (UNCHANGED) ---
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   await FirebaseNotificationService.init();
//   debugPrint("📲 Handling a background Firebase message: ${message.messageId}");
//   FirebaseNotificationService.showLocalNotification(
//     title: message.data['title'] ?? 'New Message',
//     body: message.data['body'] ?? 'You have a new message from Minber TV.',
//   );
// }

// // --- MAIN FUNCTION (UNCHANGED) ---
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final savedThemeMode = await loadThemePreference();
//   themeNotifier = ValueNotifier<ThemeMode>(savedThemeMode);

//   try {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     debugPrint(
//         "✅ Firebase Core initialized successfully with project options.");
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   } catch (e) {
//     debugPrint("🔥 FATAL: Firebase Core initialization failed: $e");
//   }

//   await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
//   await Workmanager().registerPeriodicTask(
//     "1",
//     "dailyPrayerNotificationScheduler",
//     frequency: const Duration(hours: 24),
//     constraints: Constraints(networkType: NetworkType.connected),
//   );

//   final prefs = await SharedPreferences.getInstance();
//   await NotificationService.init();
//   await FirebaseNotificationService.init();

//   NotificationService.scheduleDailyAndWeeklyNotifications();
//   setupFirebasePushNotifications();

//   final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
//   final seenOnboarding = prefs.getBool('onboarding_complete') ?? false;

//   String initialRoute = '/onboarding';
//   if (isLoggedIn) {
//     initialRoute = '/home';
//   } else if (seenOnboarding) {
//     initialRoute = '/login';
//   }

//   debugPrint('➡️ App Start → navigating to $initialRoute');
//   runApp(MyApp(initialRoute: initialRoute));
// }

// // --- ✅ UPDATE 2: FUNCTION TO SHOW CUSTOM IN-APP NOTIFICATION ---
// void showInAppNotification(String title, String body) {
//   scaffoldMessengerKey.currentState?.showSnackBar(
//     SnackBar(
//       content: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//           if (body.isNotEmpty) Text(body),
//         ],
//       ),
//       behavior: SnackBarBehavior.floating,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       margin: const EdgeInsets.fromLTRB(15, 5, 15, 10),
//       action: SnackBarAction(
//         label: 'View',
//         onPressed: () {
//           NotificationService.navigatorKey.currentState
//               ?.pushNamed('/notifications');
//         },
//       ),
//     ),
//   );
// }

// // --- FIREBASE PUSH NOTIFICATION SETUP (UPDATED) ---
// Future<void> setupFirebasePushNotifications() async {
//   try {
//     FirebaseMessaging messaging = FirebaseMessaging.instance;

//     NotificationSettings settings = await messaging.requestPermission();
//     if (settings.authorizationStatus != AuthorizationStatus.authorized) {
//       debugPrint('🚫 Firebase Messaging permission denied.');
//       return;
//     }
//     debugPrint('✅ Firebase Messaging permission granted.');

//     await messaging.subscribeToTopic('all');
//     debugPrint("📢 Subscribed to Firebase topic: all");

//     final token = await messaging.getToken();
//     debugPrint('🔥 Initial FCM Device Token: $token');

//     FirebaseMessaging.instance.onTokenRefresh.listen((newFcmToken) async {
//       debugPrint('🔄 FCM Token has been refreshed. New token: $newFcmToken');
//       final prefs = await SharedPreferences.getInstance();
//       final accessToken = prefs.getString('accessToken');
//       if (accessToken != null) {
//         debugPrint('User is logged in. Updating refreshed token on server...');
//         await ApiService.updateFcmToken(newFcmToken, accessToken);
//       } else {
//         debugPrint('User is not logged in. No need to update token on server.');
//       }
//     }).onError((err) {
//       debugPrint("❌ Error in onTokenRefresh listener: $err");
//     });

//     // --- ✅ UPDATE 4: THIS LISTENER NOW SHOWS THE CUSTOM SNACKBAR ---
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       debugPrint(
//           "💬 Firebase foreground message received: ${message.notification?.title}");
//       String title = message.notification?.title ??
//           message.data['title'] ??
//           "New Notification";
//       String body = message.notification?.body ?? message.data['body'] ?? "";

//       // Instead of showing a system notification, we show our custom in-app one.
//       showInAppNotification(title, body);
//     });

//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       debugPrint(
//           '🚀 App opened from Firebase notification: ${message.notification?.title}');
//       final navigator = NotificationService.navigatorKey.currentState;
//       navigator?.pushNamed('/notifications');
//     });
//   } catch (e) {
//     debugPrint("❌ ERROR setting up Firebase Push Notifications: $e");
//   }
// }

// // --- MAIN APP WIDGET (UPDATED) ---
// class MyApp extends StatelessWidget {
//   final String initialRoute;
//   const MyApp({super.key, required this.initialRoute});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (context) => UserProvider()),
//         ChangeNotifierProvider(create: (context) => PrayerProvider()),
//       ],
//       child: ValueListenableBuilder<ThemeMode>(
//         valueListenable: themeNotifier,
//         builder: (_, ThemeMode currentMode, __) {
//           return MaterialApp(
//             // --- ✅ UPDATE 3: ATTACH THE GLOBAL KEY TO MATERIALAPP ---
//             scaffoldMessengerKey: scaffoldMessengerKey,
//             navigatorKey: NotificationService.navigatorKey,
//             debugShowCheckedModeBanner: false,
//             title: 'Minber TV',
//             theme: ThemeData(
//               primaryColor: AppColors.primaryBlue,
//               scaffoldBackgroundColor: AppColors.backgroundLight,
//               appBarTheme: const AppBarTheme(
//                 backgroundColor: AppColors.backgroundLight,
//                 foregroundColor: AppColors.primaryBlue,
//                 elevation: 0.0,
//                 scrolledUnderElevation: 1.0,
//                 titleTextStyle: TextStyle(
//                   color: AppColors.primaryBlue,
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 iconTheme: IconThemeData(color: AppColors.primaryBlue),
//               ),
//               brightness: Brightness.light,
//               colorScheme: const ColorScheme.light(
//                 primary: AppColors.primaryBlue,
//                 secondary: AppColors.accentBlue,
//                 surface: AppColors.backgroundLight,
//                 onBackground: AppColors.textGrey,
//                 onSurface: AppColors.textGrey,
//               ),
//               textTheme: const TextTheme(
//                 bodyLarge: TextStyle(color: Color.fromARGB(255, 61, 61, 61)),
//                 bodyMedium: TextStyle(color: Colors.black54),
//               ),
//             ),
//             darkTheme: ThemeData(
//               primaryColor: const Color.fromARGB(255, 27, 127, 209),
//               scaffoldBackgroundColor: AppColors.backgroundDark,
//               appBarTheme: const AppBarTheme(
//                 backgroundColor: AppColors.surfaceDark,
//                 foregroundColor: Colors.white,
//                 elevation: 2.0,
//                 titleTextStyle: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 iconTheme: IconThemeData(color: Colors.white70),
//               ),
//               brightness: Brightness.dark,
//               colorScheme: const ColorScheme.dark(
//                 primary: AppColors.primaryBlue,
//                 secondary: AppColors.accentBlue,
//                 surface: AppColors.surfaceDark,
//                 onBackground: Colors.white70,
//                 onSurface: Colors.white70,
//               ),
//               textTheme: const TextTheme(
//                 bodyLarge: TextStyle(color: Colors.white70),
//                 bodyMedium: TextStyle(color: Colors.white54),
//               ),
//             ),
//             themeMode: currentMode,
//             initialRoute: initialRoute,
//             routes: {
//               '/onboarding': (_) => const OnboardingScreen(),
//               '/home': (_) => const HomeScreen(),
//               '/login': (_) => const LoginPage(),
//               '/signup': (_) => const SignUpPage(),
//               '/profile': (_) => const ProfilePage(),
//               '/forgot-password': (_) => const ForgotPasswordScreen(),
//               '/reset-password': (_) => const ResetPasswordScreen(),
//               '/changePassword': (_) => const ChangePasswordPage(),
//               '/live': (_) => const LiveStreamPage(),
//               '/media': (_) => const MediaHubScreen(),
//               '/news': (context) {
//                 final args = ModalRoute.of(context)!.settings.arguments
//                     as Map<String, dynamic>;
//                 return NewsSeeAllPage(
//                   newsArticles: args['newsArticles'] as List<dynamic>,
//                   apiBaseUrl: args['apiBaseUrl'] as String,
//                 );
//               },
//               '/youtubeContent': (_) => const OnDemandPage(),
//               '/channel': (_) => const YouTubeChannelDetailPage(),
//               '/ondemand': (_) => const OnDemandPage(),
//               '/prayer': (_) => const PrayerTimesPage(),
//               '/hijri-calendar': (_) => const HijriCalendarPage(),
//               '/qibla-compass': (_) => const QiblaCompassPage(),
//               '/chatbot': (_) => const ChatBotPage(),
//               '/notifications': (_) => const NotificationsPage(),
//               '/subscription': (_) => const SubscriptionPage(),
//               '/upgradeplan': (_) => const UpgradePlanPage(),
//               '/subapps': (_) => const KiriyogdeyraPage(),
//               '/dua-dhikr': (_) => const DuaDhikrPage(),
//               '/notification-settings': (_) => const NotificationSettingsPage(),
//               '/about-us': (_) => const AboutUsPage(),
//               '/help-and-support': (_) => const HelpAndSupportPage(),
//               '/coming-soon': (_) => const ComingSoonPage(),
//             },
//           );
//         },
//       ),
//     );
//   }
// }
// lib/main.dart (Final Version with Custom Animated Banner)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:minber_super_app_new_fixed/screens/YouTube_screen.dart';
import 'package:minber_super_app_new_fixed/screens/about_us_page.dart';
import 'package:minber_super_app_new_fixed/screens/coming_soon_page.dart';
import 'package:minber_super_app_new_fixed/screens/help_and_support_page.dart';
import 'package:minber_super_app_new_fixed/screens/media/media_hub_screen.dart';
import 'package:minber_super_app_new_fixed/screens/news_see_all_page.dart';
import 'package:minber_super_app_new_fixed/screens/notification_settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:provider/provider.dart';

// --- SERVICE IMPORTS ---
import 'services/notification_service.dart'; // For LOCAL prayer notifications
import 'services/firebase-notification.dart'; // For FIREBASE push notifications
import 'widgets/in_app_notification_banner.dart'; // ✅ THE NEW BANNER WIDGET

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

// --- MAIN FUNCTION (UNCHANGED) ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedThemeMode = await loadThemePreference();
  themeNotifier = ValueNotifier<ThemeMode>(savedThemeMode);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint(
        "✅ Firebase Core initialized successfully with project options.");
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

// --- FIREBASE PUSH NOTIFICATION SETUP (UPDATED) ---
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

    // --- ✅ FINAL UPDATE: CALLS THE NEW OVERLAY NOTIFICATION MANAGER ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          "💬 Firebase foreground message received: ${message.notification?.title}");
      String title = message.notification?.title ??
          message.data['title'] ??
          "New Notification";
      String body = message.notification?.body ?? message.data['body'] ?? "";

      // Show the new, custom, animated banner from the top
      showOverlayNotification(title: title, body: body);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
          '🚀 App opened from Firebase notification: ${message.notification?.title}');
      NotificationService.navigatorKey.currentState?.pushNamed('/notifications');
    });
  } catch (e) {
    debugPrint("❌ ERROR setting up Firebase Push Notifications: $e");
  }
}

// --- MAIN APP WIDGET (UNCHANGED) ---
// This uses your existing NotificationService.navigatorKey which is correct.
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
            },
          );
        },
      ),
    );
  }
}