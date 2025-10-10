// lib/screens/onboarding_screen.dart (Fully Updated & Ready to Paste)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // ✅ UI/UX UPDATE: Import for modern page indicator

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  // ✅ UI/UX UPDATE: For animating the logo
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onNextTap() {
    if (_currentPage == 2) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text("Skip"),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  // --- Page 1: Welcome ---
                  _buildPage(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ✅ UI/UX UPDATE: Animated logo
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Image.asset("assets/images/minber.jpg",
                              height: 120),
                        ),
                        const SizedBox(height: 40),
                        Text("Welcome to Minber Super App",
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text(
                            "Your everyday companion: shop, stream, pray, and pay in one seamless experience.",
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge
                                ?.copyWith(color: theme.hintColor)),
                      ],
                    ),
                  ),

                  // --- Page 2: Features ---
                  _buildPage(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("All Your Essentials, One App",
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            _FeatureChip(
                                icon: Icons.live_tv_rounded,
                                label: "Live Streaming"),
                            _FeatureChip(
                                icon: Icons.credit_card_rounded,
                                label: "Halal Pay"),
                            _FeatureChip(
                                icon: Icons.mosque_rounded,
                                label: "Prayer Times"),
                            _FeatureChip(
                                icon: Icons.calendar_month_rounded,
                                label: "Hijri Calendar"),
                            _FeatureChip(
                                icon: Icons.smart_toy_rounded,
                                label: "AI Chatbot"),
                            _FeatureChip(
                                icon: Icons.widgets_rounded,
                                label: "And More!"),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- Page 3: Get Started ---
                  _buildPage(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_alt_1_rounded,
                            size: 100, color: theme.colorScheme.primary),
                        const SizedBox(height: 24),
                        Text("Join the Community",
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text(
                            "Create an account or sign in to personalize your experience and unlock all features.",
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge
                                ?.copyWith(color: theme.hintColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ✅ UI/UX UPDATE: Modern Page Indicator and Animated Button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 3,
                    effect: ExpandingDotsEffect(
                      activeDotColor: theme.colorScheme.primary,
                      dotColor: theme.dividerColor,
                      dotHeight: 10,
                      dotWidth: 10,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _onNextTap,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _currentPage == 2 ? "Get Started" : "Next",
                          key: ValueKey<int>(
                              _currentPage), // Key to trigger animation
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  if (_currentPage == 2)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: _completeOnboarding,
                        child: const Text("I already have an account"),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: child,
    );
  }
}

// ✅ UI/UX UPDATE: A cleaner, reusable chip for features
class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, color: theme.colorScheme.primary, size: 20),
      label: Text(label),
      labelStyle:
          theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      side: BorderSide.none,
    );
  }
}
