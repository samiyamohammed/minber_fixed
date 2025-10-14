// lib/screens/coming_soon_page.dart (New File - Ready to Paste)

import 'package:flutter/material.dart';

class ComingSoonPage extends StatefulWidget {
  const ComingSoonPage({super.key});

  @override
  State<ComingSoonPage> createState() => _ComingSoonPageState();
}

class _ComingSoonPageState extends State<ComingSoonPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true); // Loop the animation back and forth

    _animation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the feature name passed from the previous screen
    final String featureName =
        ModalRoute.of(context)?.settings.arguments as String? ?? "This feature";
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(featureName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
              RotationTransition(
                turns: _animation,
                child: Icon(
                  Icons.rocket_launch_outlined,
                  size: 120,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Main text
              Text(
                "Coming Soon!",
                style: textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Subtitle text
              Text(
                "We're working hard to bring '$featureName' to you. Stay tuned for exciting updates!",
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 40),

              // Go Back button
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Go Back"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
