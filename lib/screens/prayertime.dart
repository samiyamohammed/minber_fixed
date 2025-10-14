// lib/screens/prayertime.dart (Fully Updated & Ready to Paste)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart'; // ✅ SOLUTION: Import the provider

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  // All business logic and state are now in PrayerProvider.
  // This widget is only responsible for building the UI.

  int _selectedIndex = 2; // For BottomNavBar

  final Map<String, IconData> _prayerIcons = {
    "Fajr": Icons.wb_twilight_rounded,
    "Sunrise": Icons.wb_sunny_outlined,
    "Dhuhr": Icons.wb_sunny_rounded,
    "Asr": Icons.wb_cloudy_rounded,
    "Maghrib": Icons.wb_twilight_outlined,
    "Isha": Icons.nights_stay_rounded,
  };

  // Your navigation logic remains the same. The provider ensures that even if this
  // page is rebuilt, the data is not re-fetched.
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    String routeName = '';
    switch (index) {
      case 0:
        routeName = '/home';
        break;
      case 1:
        routeName = '/media';
        break;
      case 2:
        break; // Current page, do nothing
      case 3:
        routeName = '/chatbot';
        break;
      case 4:
        routeName = '/subapps';
        break;
    }
    if (routeName.isNotEmpty) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ✅ SOLUTION: Listen to the PrayerProvider for state changes.
    // context.watch makes this widget rebuild whenever notifyListeners() is called.
    final prayerProvider = context.watch<PrayerProvider>();

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(theme, prayerProvider),
          Expanded(
            child: prayerProvider.isLoading
                ? const _PrayerListShimmer()
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildPrayerList(theme, prayerProvider),
                      const SizedBox(height: 24),
                      _buildToolsGrid(theme),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  // --- WIDGET BUILDER METHODS ---
  // These now take the provider as an argument to get the data they need.

  Widget _buildHeader(ThemeData theme, PrayerProvider provider) {
    final formattedHijriDate = HijriCalendar.now().toFormat("MMMM d, yyyy");
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/images/mosque.jpg"),
                  fit: BoxFit.cover)),
        ),
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.6),
                theme.colorScheme.primary.withOpacity(0.4),
                theme.scaffoldBackgroundColor.withOpacity(0.2)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  // ✅ SOLUTION: Use data from the provider
                  Text("${provider.city}, ${provider.country}",
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w500))
                ]),
                const SizedBox(height: 8),
                // ✅ SOLUTION: Use data from the provider
                Text(provider.nextPrayer,
                    style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                // ✅ SOLUTION: Use data from the provider
                if (provider.nextPrayerCountdown.isNotEmpty)
                  Text("in ${provider.nextPrayerCountdown}",
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: Colors.white70)),
                const SizedBox(height: 12),
                Chip(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  label: Text(
                      "${DateFormat("MMMM d, yyyy").format(DateTime.now())} | $formattedHijriDate",
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerList(ThemeData theme, PrayerProvider provider) {
    // ✅ SOLUTION: Use data from the provider
    return Column(
      children: provider.prayerTimes.entries.map((entry) {
        final isNext = entry.key == provider.nextPrayer;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color:
                isNext ? theme.colorScheme.primaryContainer : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(_prayerIcons[entry.key],
                  color: isNext
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  entry.key,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isNext
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                DateFormat("h:mm a").format(entry.value),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isNext
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.notifications_active_outlined,
                  size: 20,
                  color: isNext
                      ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7)
                      : theme.hintColor.withOpacity(0.7)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToolsGrid(ThemeData theme) {
    final tools = [
      {
        'name': 'Hijri Calendar',
        'icon': Icons.calendar_month_rounded,
        'route': '/hijri-calendar'
      },
      {
        'name': 'Qibla Compass',
        'icon': Icons.explore_rounded,
        'route': '/qibla-compass'
      },
      {'name': 'Dua & Dhikr', 'icon': Icons.book_rounded, 'route': '/dua-dhikr'}
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, tool['route'] as String),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(tool['icon'] as IconData,
                        color: theme.colorScheme.onPrimary, size: 24)),
                const SizedBox(height: 12),
                Text(tool['name'] as String,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  BottomNavigationBar _buildBottomNavBar(ThemeData theme) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.unselectedWidgetColor,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.tv_outlined),
            activeIcon: Icon(Icons.tv),
            label: "Media"),
        BottomNavigationBarItem(
            icon: Icon(Icons.mosque_outlined),
            activeIcon: Icon(Icons.mosque),
            label: "Prayer"),
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: "Chat Bot"),
        BottomNavigationBarItem(
            icon: Icon(Icons.apps),
            activeIcon: Icon(Icons.apps),
            label: "Sub Apps"),
      ],
    );
  }
}

// This shimmer widget remains completely unchanged.
class _PrayerListShimmer extends StatelessWidget {
  const _PrayerListShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.splashColor,
      highlightColor: theme.cardColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const CircleAvatar(radius: 16, backgroundColor: Colors.white),
              const SizedBox(width: 16),
              Container(width: 80, height: 16, color: Colors.white),
              const Spacer(),
              Container(width: 100, height: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
