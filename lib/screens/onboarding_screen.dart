import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // adapts to theme
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  // Onboarding 1
                  _buildPage(
                    size,
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/minber.jpg",
                          width: size.width * 0.5,
                          height: size.height * 0.25,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: size.height * 0.05),
                        Text(
                          "Welcome to Minber Super App!",
                          style: TextStyle(
                            fontSize: size.width * 0.055,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge!.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.02),
                        Text(
                          "Your everyday companion: shop, stream, pray, and pay in one app.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            color: theme.textTheme.bodyMedium!.color,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Onboarding 2
                  _buildPage(
                    size,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Discover convenience and connection with all your daily essentials in one app.",
                          style: TextStyle(
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyLarge!.color,
                          ),
                        ),
                        SizedBox(height: size.height * 0.03),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _FeatureCard(
                              title: "Live Streaming",
                              subtitle: "Enjoy live TV and shows",
                              width:
                                  (size.width - (size.width * 0.16) - 16) / 2,
                              theme: theme,
                            ),
                            _FeatureCard(
                              title: "Halal Pay",
                              subtitle: "Secure Islamic payments",
                              width:
                                  (size.width - (size.width * 0.16) - 16) / 2,
                              theme: theme,
                            ),
                            _FeatureCard(
                              title: "Prayer Times",
                              subtitle: "Accurate timings & Qibla",
                              width:
                                  (size.width - (size.width * 0.16) - 16) / 2,
                              theme: theme,
                            ),
                            _FeatureCard(
                              title: "Hijri Calendar",
                              subtitle: "Islamic dates & events",
                              width:
                                  (size.width - (size.width * 0.16) - 16) / 2,
                              theme: theme,
                            ),
                            _FeatureCard(
                              title: "AI Chatbot",
                              subtitle: "Instant help & reminders",
                              width:
                                  (size.width - (size.width * 0.16) - 16) / 2,
                              theme: theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Onboarding 3
                  _buildPage(
                    size,
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group,
                          size: size.width * 0.4,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: size.height * 0.05),
                        Text(
                          "Ready to personalize your experience?",
                          style: TextStyle(
                            fontSize: size.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge!.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: size.height * 0.02),
                        Text(
                          "Create an account or log in to get started!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            color: theme.textTheme.bodyMedium!.color,
                          ),
                        ),
                        SizedBox(height: size.height * 0.06),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('onboarding_complete', true);
                              if (!mounted) return;
                              Navigator.pushReplacementNamed(
                                context,
                                '/signup',
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(
                                vertical: size.height * 0.02,
                              ),
                            ),
                            child: Text(
                              "Create an Account",
                              style: TextStyle(
                                fontSize: size.width * 0.045,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.015),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('onboarding_complete', true);
                              if (!mounted) return;
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: size.height * 0.02,
                              ),
                              side: BorderSide(color: AppColors.primary),
                            ),
                            child: Text(
                              "Log In",
                              style: TextStyle(
                                fontSize: size.width * 0.045,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Button (only show for pages 0 and 1)
            if (_currentPage < 2)
              Padding(
                padding: EdgeInsets.all(size.width * 0.06),
                child: ElevatedButton(
                  onPressed: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(
                      vertical: size.height * 0.018,
                      horizontal: size.width * 0.2,
                    ),
                  ),
                  child: Text(
                    "Next",
                    style: TextStyle(
                      fontSize: size.width * 0.045,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Size size, Widget child) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(size.width * 0.08),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size.height * 0.8),
        child: child,
      ),
    );
  }
}

// Updated Feature Card with theming
class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double width;
  final ThemeData theme;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.width,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: theme.cardColor, // adapts to theme
      ),
      padding: EdgeInsets.all(size.width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: size.width * 0.1,
          ),
          SizedBox(height: size.height * 0.01),
          Text(
            title,
            style: TextStyle(
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge!.color,
            ),
          ),
          SizedBox(height: size.height * 0.005),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: size.width * 0.035,
              color: theme.textTheme.bodyMedium!.color,
            ),
          ),
        ],
      ),
    );
  }
}
