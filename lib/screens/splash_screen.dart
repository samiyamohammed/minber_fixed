// lib/screens/splash_screen.dart (Fully Updated & Ready to Paste)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import '../api/firebase_api.dart'; // Assuming this path is correct
import '../services/notification_service.dart'; // Assuming this path is correct

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// ✅ UI/UX UPDATE: Added TickerProviderStateMixin for animations
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start the animation and then the initialization logic
    _animationController.forward();
    _initializeAppAndNavigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- CORE LOGIC (Unchanged) ---
  Future<void> _initializeAppAndNavigate() async {
    final setupStart = DateTime.now();
    try {
      // These can run in parallel for speed
      await Future.wait([
        SharedPreferences.getInstance(),
        Firebase.initializeApp().timeout(const Duration(seconds: 5)),
      ]);

      final prefs = await SharedPreferences.getInstance();

      // Don't need to await these fully, they can finish in the background
      FirebaseApi().initNotifications();
      NotificationService.init();

      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final seenOnboarding = prefs.getBool('onboarding_complete') ?? false;

      // Ensure splash is visible for a minimum duration
      final duration = DateTime.now().difference(setupStart);
      const minimumDelay = Duration(seconds: 2, milliseconds: 500); // Slightly longer for a smoother feel
      if (duration < minimumDelay) {
        await Future.delayed(minimumDelay - duration);
      }

      if (!mounted) return;

      String routeName;
      if (isLoggedIn) {
        routeName = '/home';
      } else if (seenOnboarding) {
        routeName = '/login';
      } else {
        routeName = '/onboarding';
      }
      Navigator.pushReplacementNamed(context, routeName);

    } catch (e) {
      debugPrint("❌ ERROR during initialization: $e");
      if (mounted) Navigator.pushReplacementNamed(context, '/login'); // Fallback to login on error
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ UI/UX UPDATE: Animated Logo
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                // Use the official logo.png for brand consistency
                child: Image.asset("assets/images/minber.jpg", width: 150),
              ),
            ),
            const SizedBox(height: 40),
            // ✅ UI/UX UPDATE: Loading indicator for user feedback
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}