import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('onboarding_complete') ?? false;

    Timer(const Duration(seconds: 2), () {
      if (seenOnboarding) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get current theme

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // adapt to light/dark
      body: Center(
        child: Image.asset(
          "assets/images/minber.jpg",
          width: MediaQuery.of(context).size.width * 0.5,
        ),
      ),
    );
  }
}
