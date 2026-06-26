// lib/main_web.dart - Web-specific entry point

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:minber/providers/ramadan_provider.dart';
import 'package:minber/screens/ramadan_quiz_screen.dart';
import 'package:minber/widgets/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
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
import 'screens/about_us_page.dart';
import 'screens/coming_soon_page.dart';
import 'screens/help_and_support_page.dart';
import 'screens/media/media_hub_screen.dart';
import 'screens/news_see_all_page.dart';
import 'screens/notification_settings_page.dart';
import 'screens/update_profile_page.dart';
import 'services/api_service.dart';
import 'firebase_options.dart';
import 'providers/notification_settings_provider.dart';

final logger = Logger();

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final savedThemeMode = await loadThemePreference();
  themeNotifier = ValueNotifier<ThemeMode>(savedThemeMode);

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("🔥 Firebase Init failed: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final isGuest = prefs.getBool('isGuest') ?? false;
  final seenOnboarding = prefs.getBool('onboarding_complete') ?? false;

  // For web demo, skip onboarding and go straight to home as guest
  String initialRoute = '/home';
  // Set guest mode for web
  await prefs.setBool('isGuest', true);

  debugPrint('➡️ App Start → navigating to $initialRoute');
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
            navigatorKey: navigatorKey,
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
