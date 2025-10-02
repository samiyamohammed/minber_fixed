// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'api/firebase_api.dart';
// import 'services/notification_service.dart';

// import 'screens/splash_screen.dart';
// import 'screens/onboarding_screen.dart';
// import 'screens/home_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/signup_screen.dart';
// import 'screens/Profile & Settings.dart';
// import 'screens/edit_profile.dart';
// import 'screens/change_password.dart';
// import 'screens/live_screen.dart';
// import 'screens/media.dart';
// import 'screens/youtube_screen.dart';
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
// import 'core/app_colors.dart';

// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// // --- Theme Handling ---
// ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

// Future<void> saveThemePreference(ThemeMode mode) async {
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.setInt('themeMode', mode.index);
// }

// Future<void> loadThemePreference() async {
//   final prefs = await SharedPreferences.getInstance();
//   final themeIndex = prefs.getInt('themeMode') ?? ThemeMode.system.index;
//   themeNotifier.value = ThemeMode.values[themeIndex];
// }

// Future<ThemeMode> getSystemThemeMode() async {
//   final isSystemDarkMode =
//       WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
//   return isSystemDarkMode ? ThemeMode.dark : ThemeMode.light;
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Firebase FIRST
//   await Firebase.initializeApp();
//   await FirebaseApi().initNotifications();

//   // Initialize NotificationService right after Firebase, as it doesn't need a Context
//   // You do not need to pass a Context (param0) to init() if you don't use it in NotificationService.
//   // We will pass null or remove the parameter from init if it's truly not needed.
//   // Based on your NotificationService, it does NOT need a BuildContext, so we call it here.
//   // **NOTE:** If you eventually need the context for navigation, the logic below is better.
//   // For now, let's call the init() without a context, and fix your init signature.
//   // Assuming you update NotificationService.init to: static Future<void> init() async { ... }
//   // If you *need* the param0, the safest place is in addPostFrameCallback.

//   // --- SAFE APPROACH (IF BuildContext is needed for navigation handling) ---
//   await loadThemePreference();

//   // If the loaded preference is ThemeMode.system, then check the device's current theme
//   if (themeNotifier.value == ThemeMode.system) {
//     final systemTheme = await getSystemThemeMode();
//     themeNotifier.value =
//         systemTheme; // Set the initial theme based on the system
//   }
//   // --- END FIX ---

//   runApp(const MyApp());

//   // Initialize NotificationService AFTER runApp and the first frame,
//   // when navigatorKey.currentContext will be available for navigation.
//   WidgetsBinding.instance.addPostFrameCallback((_) async {
//     final context = navigatorKey.currentContext;
//     if (context != null) {
//       // NOTE: We pass the context, but your current NotificationService
//       // only uses it for the signature. If you intend to use it later,
//       // this is the correct place to call it.
//       await NotificationService.init(context);
//     }
//   });
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<ThemeMode>(
//       valueListenable: themeNotifier,
//       builder: (_, ThemeMode currentMode, __) {
//         return MaterialApp(
//           navigatorKey: navigatorKey,
//           debugShowCheckedModeBanner: false,
//           title: 'Minber TV',
//           theme: ThemeData(
//             primaryColor: AppColors.primary,
//             scaffoldBackgroundColor: AppColors.background,
//             appBarTheme: AppBarTheme(
//               backgroundColor: AppColors.primary,
//               foregroundColor: Colors.white,
//               elevation: 0,
//               titleTextStyle: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//               iconTheme: const IconThemeData(color: Colors.white),
//             ),
//             brightness: Brightness.light,
//             colorScheme: ColorScheme.light(
//               primary: AppColors.primary,
//               secondary: Colors.tealAccent,
//               surface: Colors.white,
//               onBackground: Colors.black87,
//               onSurface: Colors.black87,
//             ),
//             textTheme: const TextTheme(
//               bodyLarge: TextStyle(color: Colors.black87),
//               bodyMedium: TextStyle(color: Colors.black87),
//             ),
//           ),
//           darkTheme: ThemeData(
//             primaryColor: AppColors.primary,
//             scaffoldBackgroundColor: const Color(0xFF121212),
//             appBarTheme: const AppBarTheme(
//               backgroundColor: Color(0xFF1F1F1F),
//               foregroundColor: Colors.white,
//               elevation: 0,
//               titleTextStyle: TextStyle(
//                 color: Colors.white,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//               iconTheme: IconThemeData(color: Colors.white70),
//             ),
//             brightness: Brightness.dark,
//             colorScheme: ColorScheme.dark(
//               primary: AppColors.primary,
//               // Null check removed: Secondary color for dark mode should be safe
//               secondary: Colors.tealAccent,
//               surface: const Color(0xFF1F1F1F),
//               onBackground: Colors.white70,
//               onSurface: Colors.white70,
//             ),
//             textTheme: const TextTheme(
//               bodyLarge: TextStyle(color: Colors.white70),
//               bodyMedium: TextStyle(color: Colors.white70),
//             ),
//           ),
//           themeMode: currentMode,
//           initialRoute: '/',
//           routes: {
//             '/': (_) => const SplashScreen(),
//             '/onboarding': (_) => const OnboardingScreen(),
//             '/home': (_) => const HomeScreen(),
//             '/login': (_) => const LoginPage(),
//             '/signup': (_) => const SignUpPage(),
//             '/profile': (_) => const ProfilePage(),
//             '/editProfile': (_) => const EditProfilePage(),
//             '/changePassword': (_) => const ChangePasswordPage(),
//             '/live': (_) => const LivePage(),
//             '/media': (_) => const MediaHubPage(),
//             '/youtube': (_) => const YouTubePage(),
//             '/youtubeContent': (_) => const OnDemandPage(),
//             '/channel': (_) => const YouTubeChannelDetailPage(),
//             '/ondemand': (_) => const OnDemandPage(),
//             '/prayer': (_) => const PrayerTimesPage(),
//             '/hijri-calendar': (_) => const HijriCalendarPage(),
//             '/qibla-compass': (_) => const QiblaCompassPage(),
//             '/chatbot': (_) => const ChatBotPage(),
//             '/notifications': (_) => const NotificationsPage(),
//             '/subscription': (_) => const SubscriptionPage(),
//             '/upgradeplan': (_) => const UpgradePlanPage(),
//             '/subapps': (_) => const KiriyogdeyraPage(),
//             '/dua-dhikr': (context) => const DuaDhikrPage(),
//           },
//         );
//       },
//     );
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'api/firebase_api.dart';
import 'services/notification_service.dart';

import 'screens/splash_screen.dart';
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
import 'core/app_colors.dart';

// --- Theme Handling ---
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

Future<ThemeMode> getSystemThemeMode() async {
  final isSystemDarkMode =
      WidgetsBinding.instance.window.platformBrightness == Brightness.dark;
  return isSystemDarkMode ? ThemeMode.dark : ThemeMode.light;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  await FirebaseApi().initNotifications();

  // Load theme preferences
  await loadThemePreference();
  if (themeNotifier.value == ThemeMode.system) {
    final systemTheme = await getSystemThemeMode();
    themeNotifier.value = systemTheme;
  }

  runApp(const MyApp());

  // Initialize NotificationService AFTER runApp so navigator is ready
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await NotificationService.init();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          navigatorKey:
              NotificationService.navigatorKey, // use service navigatorKey
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
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/home': (_) => const HomeScreen(),
            '/login': (_) => const LoginPage(),
            '/signup': (_) => const SignUpPage(),
            '/profile': (_) => const ProfilePage(),
            '/editProfile': (_) => const EditProfilePage(),
            '/changePassword': (_) => const ChangePasswordPage(),
            '/live': (_) => const LivePage(),
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
    );
  }
}
