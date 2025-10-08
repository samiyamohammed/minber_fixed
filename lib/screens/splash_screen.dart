import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import '../api/firebase_api.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAppAndNavigate();
  }

  Future<void> _initializeAppAndNavigate() async {
    final setupStart = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    try {
      // Initialize Firebase (but don't block navigation forever)
      try {
        await Firebase.initializeApp().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint("⚠️ Firebase initialization timed out.");
            throw Exception("Firebase initialization timed out.");
          },
        );
      } catch (e) {
        debugPrint("⚠️ Firebase init error: $e");
      }

      // Initialize Notifications (Firebase + local)
      try {
        await FirebaseApi().initNotifications().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint("⚠️ FirebaseApi notifications init timed out.");
          },
        );
      } catch (e) {
        debugPrint("⚠️ FirebaseApi init error: $e");
      }

      try {
        await NotificationService.init().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint("⚠️ Local notifications init timed out.");
          },
        );
      } catch (e) {
        debugPrint("⚠️ NotificationService init error: $e");
      }

      // Load login data from SharedPreferences
      final accessToken = prefs.getString('accessToken');
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final seenOnboarding = prefs.getBool('onboarding_complete') ?? false;

      // Debug prints to understand what splash sees
      debugPrint('🔎 SPLASH DEBUG → accessToken: ${accessToken ?? "NULL"}');
      debugPrint('🔎 SPLASH DEBUG → isLoggedIn: $isLoggedIn');
      debugPrint('🔎 SPLASH DEBUG → onboarding_complete: $seenOnboarding');

      // Keep splash screen visible at least 2 seconds for better UX
      final duration = DateTime.now().difference(setupStart);
      const minimumDelay = Duration(seconds: 2);
      if (duration < minimumDelay) {
        await Future.delayed(minimumDelay - duration);
      }

      if (!mounted) return;

      // ✅ Decide where to go
      if (isLoggedIn && accessToken != null && accessToken.isNotEmpty) {
        debugPrint('➡️ Splash → navigating to /home');
        Navigator.pushReplacementNamed(context, '/home');
      } else if (seenOnboarding) {
        debugPrint('➡️ Splash → navigating to /login');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        debugPrint('➡️ Splash → navigating to /onboarding');
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } catch (e, st) {
      debugPrint("❌ ERROR during initialization: $e\n$st");
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Image.asset(
          "assets/images/minber.jpg",
          width: MediaQuery.of(context).size.width * 0.5,
        ),
      ),
    );
  }
}
