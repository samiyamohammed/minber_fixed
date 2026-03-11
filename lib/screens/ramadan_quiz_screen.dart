import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../providers/ramadan_provider.dart';
import '../models/ramadan_question.dart';

class RamadanQuizScreen extends StatefulWidget {
  const RamadanQuizScreen({super.key});

  @override
  State<RamadanQuizScreen> createState() => _RamadanQuizScreenState();
}

class _RamadanQuizScreenState extends State<RamadanQuizScreen>
    with SingleTickerProviderStateMixin {
  String? selectedOptionId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    Future.microtask(() => context.read<RamadanProvider>().initialize());
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;

    final provider = context.read<RamadanProvider>();
    if (_tabController.index == 1) {
      provider.fetchLeaderboard();
    } else if (_tabController.index == 2) {
      provider.fetchHistory();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Ramadan Quiz",
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryBlue,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Today"),
            Tab(text: "Rankings"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuizTab(provider, theme, cardColor),
          _buildLeaderboardTab(provider, theme, cardColor),
          _buildHistoryTab(provider, theme, cardColor),
        ],
      ),
    );
  }

  // --- TAB 1: DAILY QUIZ ---
  Widget _buildQuizTab(
      RamadanProvider provider, ThemeData theme, Color cardColor) {
    switch (provider.status) {
      case RamadanStatus.loading:
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue));

      case RamadanStatus.unauthenticated:
        return _buildStatusView(
          theme,
          cardColor,
          icon: Icons.stars_rounded,
          title: "Join the Competition",
          subtitle:
              "Log in to answer daily questions, track your progress, and compete for top prizes this Ramadan!",
          buttonText: "LOG IN TO PARTICIPATE",
          onPressed: () => Navigator.pushNamed(context, '/login'),
        );

      case RamadanStatus.empty:
        return _buildStatusView(
          theme,
          cardColor,
          icon: Icons.hourglass_empty_rounded,
          title: "Check Back Soon",
          // Uses the specific message from the provider
          subtitle: provider.errorMessage ??
              "Today's questions are being prepared. Please check back after the next prayer!",
          buttonText: "BACK TO HOME",
          onPressed: () => Navigator.pop(context),
        );

      case RamadanStatus.alreadyAnswered:
        return _buildStatusView(
          theme,
          cardColor,
          icon: Icons.verified_user_rounded,
          title: "Masha'Allah!",
          subtitle:
              "You have completed today's quiz. Your participation is recorded. View your rank in the next tab!",
          buttonText: "VIEW RANKINGS",
          onPressed: () => _tabController.animateTo(1),
        );

      case RamadanStatus.error:
        return _buildStatusView(
          theme,
          cardColor,
          icon: Icons.wifi_off_rounded,
          title: "Oops!",
          // Displays the specific error message caught in provider
          subtitle: provider.errorMessage ?? "Something went wrong.",
          buttonText: "TRY AGAIN",
          onPressed: () => provider.fetchQuestions(),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: provider.progress,
            backgroundColor: theme.dividerColor.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.primaryBlue),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  currentQuestion.text,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                ...currentQuestion.options
                    .map((opt) => _optionTile(opt, theme)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: (selectedOptionId == null || provider.isSubmitting)
                  ? null
                  : () async {
                      final ok = await provider.submitAnswer(selectedOptionId!);
                      if (ok) setState(() => selectedOptionId = null);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: provider.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("SUBMIT",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // --- TAB 2: LEADERBOARD ---
  Widget _buildLeaderboardTab(
      RamadanProvider provider, ThemeData theme, Color cardColor) {
    if (provider.isLoadingLeaderboard) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }

    if (provider.leaderboardError != null) {
      return _buildStatusView(
        theme,
        cardColor,
        icon: Icons.error_outline,
        title: "Unable to load rankings",
        subtitle: provider.leaderboardError!,
        buttonText: "TRY AGAIN",
        onPressed: () => provider.fetchLeaderboard(),
      );
    }

    if (provider.leaderboard.isEmpty) {
      return Center(
          child: Text("No rankings available yet.",
              style: TextStyle(color: theme.hintColor)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.leaderboard.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = provider.leaderboard[index];
        bool isTop3 = index < 3;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: isTop3
                ? Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              _buildRankBadge(entry.rank),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.username,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                        "Accuracy: ${(entry.accuracy * 100).toStringAsFixed(0)}%",
                        style: TextStyle(color: theme.hintColor, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${entry.correctAnswers}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                          fontSize: 18)),
                  const Text("Points",
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    if (rank == 1)
      badgeColor = Colors.amber;
    else if (rank == 2)
      badgeColor = Colors.grey.shade400;
    else if (rank == 3)
      badgeColor = Colors.brown.shade300;
    else
      badgeColor = Colors.transparent;

    return Container(
      width: 35,
      height: 35,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
        border:
            rank > 3 ? Border.all(color: Colors.grey.withOpacity(0.3)) : null,
      ),
      child: Text(
        "$rank",
        style: TextStyle(
          color: rank <= 3 ? Colors.white : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- TAB 3: USER HISTORY ---
  Widget _buildHistoryTab(
      RamadanProvider provider, ThemeData theme, Color cardColor) {
    if (provider.status == RamadanStatus.unauthenticated) {
      return _buildStatusView(
        theme,
        cardColor,
        icon: Icons.history_toggle_off,
        title: "Log in to view History",
        subtitle:
            "Track your previous answers and see how you rank among others by logging in.",
        buttonText: "LOG IN",
        onPressed: () => Navigator.pushNamed(context, '/login'),
      );
    }

    if (provider.isLoadingHistory) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }

    if (provider.historyError != null) {
      return _buildStatusView(
        theme,
        cardColor,
        icon: Icons.error_outline,
        title: "Unable to load history",
        subtitle: provider.historyError!,
        buttonText: "TRY AGAIN",
        onPressed: () => provider.fetchHistory(),
      );
    }

    if (provider.history.isEmpty) {
      return Center(
          child: Text("You haven't participated in any quiz yet.",
              style: TextStyle(color: theme.hintColor)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.history.length,
      itemBuilder: (context, index) {
        final q = provider.history[index];
        final bool isCorrect = q.isCorrect ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile(
            title: Text(DateFormat('EEEE, MMM d')
                .format(DateTime.parse(q.questionDate))),
            subtitle: Text(
                isCorrect ? "Correctly Answered" : "Incorrect Answer",
                style: TextStyle(
                    color: isCorrect ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            leading: Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? Colors.green : Colors.red),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.text,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...q.options.map((opt) {
                      bool isUserChoice = opt.id == q.selectedOptionId;
                      bool isCorrectChoice = opt.id == q.correctOptionId;

                      Color textColor = Colors.grey;
                      if (isCorrectChoice) textColor = Colors.green;
                      if (isUserChoice && !isCorrectChoice)
                        textColor = Colors.red;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                                isCorrectChoice
                                    ? Icons.check
                                    : (isUserChoice
                                        ? Icons.close
                                        : Icons.circle),
                                size: 16,
                                color: textColor),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(opt.text,
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight:
                                            (isUserChoice || isCorrectChoice)
                                                ? FontWeight.bold
                                                : null))),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // --- COMMON WIDGETS ---
  Widget _optionTile(RamadanOption opt, ThemeData theme) {
    bool selected = selectedOptionId == opt.id;
    return GestureDetector(
      onTap: () => setState(() => selectedOptionId = opt.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primaryBlue : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: selected
                  ? AppColors.primaryBlue
                  : theme.dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? Colors.white : theme.hintColor),
            const SizedBox(width: 15),
            Expanded(
                child: Text(opt.text,
                    style: TextStyle(
                        color: selected ? Colors.white : null,
                        fontWeight: selected ? FontWeight.bold : null))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusView(ThemeData theme, Color cardColor,
      {required IconData icon,
      required String title,
      required String subtitle,
      required String buttonText,
      required VoidCallback onPressed}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.amber),
            const SizedBox(height: 25),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.hintColor, height: 1.5)),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(buttonText,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
