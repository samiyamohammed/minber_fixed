// lib/screens/ramadan_quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/ramadan_provider.dart';

class RamadanQuizScreen extends StatefulWidget {
  const RamadanQuizScreen({super.key});

  @override
  State<RamadanQuizScreen> createState() => _RamadanQuizScreenState();
}

class _RamadanQuizScreenState extends State<RamadanQuizScreen> {
  String? selectedOptionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RamadanProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RamadanProvider>();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDarkMode ? AppColors.backgroundDark : Colors.white;
    final cardColor =
        isDarkMode ? AppColors.surfaceDark : const Color(0xFFF7F9FC);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Ramadan Quiz",
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.brightness_3, color: Colors.amberAccent),
          )
        ],
      ),
      body: SafeArea(
        child: _buildBodyByStatus(provider, theme, cardColor),
      ),
    );
  }

  Widget _buildBodyByStatus(
      RamadanProvider provider, ThemeData theme, Color cardColor) {
    switch (provider.status) {
      case RamadanStatus.loading:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryBlue),
              const SizedBox(height: 24),
              const Text(
                "Opening the Pavilion...",
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text("Cancel", style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        );

      case RamadanStatus.unauthenticated:
        // --- MAGNIFICENT LOGIN REQUIRED VIEW ---
        return _buildStatusView(
          theme,
          cardColor,
          icon: Icons.lock_person_outlined,
          title: "Join the Celebration",
          subtitle:
              "The Ramadan Daily Quiz is an exclusive feature for our community members. Please login to answer questions, earn points, and climb the leaderboard!",
          buttonText: "LOGIN TO PARTICIPATE",
          onPressed: () => Navigator.pushNamed(context, '/login'),
          isSecondaryVisible: true,
        );

      case RamadanStatus.alreadyAnswered:
        return _buildStatusView(
          theme,
          cardColor,
          icon: Icons.stars,
          title: "Masha'Allah!",
          subtitle:
              "You have successfully completed today's questions. Your participation has been recorded for the competition. May Allah increase your knowledge!",
          buttonText: "BACK TO HOME",
          onPressed: () => Navigator.pop(context),
        );

      case RamadanStatus.empty:
        return _buildStatusView(
          theme,
          cardColor,
          icon: Icons.hourglass_empty,
          title: "Check Back Soon",
          subtitle:
              "Today's questions are being prepared. They will be published shortly. Please check back after the next prayer!",
          buttonText: "BACK TO HOME",
          onPressed: () => Navigator.pop(context),
        );

      case RamadanStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(provider.errorMessage ?? "An error occurred"),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => provider.fetchQuestions(),
                child: const Text("Try Again"),
              ),
            ],
          ),
        );

      case RamadanStatus.ready:
        return _buildQuizContent(provider, theme, cardColor);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuizContent(
      RamadanProvider provider, ThemeData theme, Color cardColor) {
    final currentQuestion = provider.questions[provider.currentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Question ${provider.currentIndex + 1} of ${provider.questions.length}",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.stars, color: Colors.amberAccent, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: provider.progress,
            minHeight: 8,
            backgroundColor: theme.dividerColor.withOpacity(0.1),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  currentQuestion.text,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                ...currentQuestion.options
                    .map((option) => _buildOptionTile(option, theme)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (selectedOptionId == null || provider.isSubmitting)
                  ? null
                  : () async {
                      final success =
                          await provider.submitAnswer(selectedOptionId!);
                      if (success) setState(() => selectedOptionId = null);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: provider.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text("SUBMIT ANSWER",
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(dynamic option, ThemeData theme) {
    bool isSelected = selectedOptionId == option.id;
    return GestureDetector(
      onTap: () => setState(() => selectedOptionId = option.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : theme.dividerColor.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? Colors.white : theme.hintColor),
                color: isSelected ? Colors.white : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check,
                      size: 14, color: AppColors.primaryBlue)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option.text,
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusView(
    ThemeData theme,
    Color cardColor, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
    bool isSecondaryVisible = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.amberAccent, size: 64),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(height: 1.5, color: theme.hintColor),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(buttonText,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (isSecondaryVisible) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Maybe Later",
                      style: TextStyle(color: theme.hintColor)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
