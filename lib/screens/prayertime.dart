// lib/screens/prayertime.dart (FINAL CORRECT VERSION - NO PERMISSION REQUEST)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
// permission_handler is no longer needed here
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_provider.dart';
import '../providers/notification_settings_provider.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  int _selectedIndex = 2;

  final Map<String, IconData> _prayerIcons = {
    "Fajr": Icons.wb_twilight_rounded,
    "Sunrise": Icons.wb_sunny_outlined,
    "Dhuhr": Icons.wb_sunny_rounded,
    "Asr": Icons.wb_cloudy_rounded,
    "Maghrib": Icons.wb_twilight_outlined,
    "Isha": Icons.nights_stay_rounded,
  };

  @override
  void initState() {
    super.initState();
    // The permission request is gone. We only initialize the provider now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PrayerProvider>(context, listen: false).initialize();
    });
  }

  // THE PERMISSION REQUESTING METHOD HAS BEEN COMPLETELY REMOVED.

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
        break;
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
    final prayerProvider = context.watch<PrayerProvider>();
    final settingsProvider = context.watch<NotificationSettingsProvider>();

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(theme, prayerProvider),
          Expanded(
            child: prayerProvider.isLoading
                ? const _PrayerListShimmer()
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildPrayerList(
                              theme, prayerProvider, settingsProvider),
                          const SizedBox(height: 16),
                          _buildToolsGrid(theme),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

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
                  Text("${provider.city}, ${provider.country}",
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w500))
                ]),
                const SizedBox(height: 8),
                Text(provider.nextPrayer,
                    style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
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

  Widget _buildPrayerList(ThemeData theme, PrayerProvider prayerProvider,
      NotificationSettingsProvider settingsProvider) {
    return Column(
      children: prayerProvider.prayerTimes.entries.map((entry) {
        final isNext = entry.key == prayerProvider.nextPrayer;

        bool isNotificationEnabled() {
          switch (entry.key) {
            case 'Fajr':
              return settingsProvider.fajr;
            case 'Dhuhr':
              return settingsProvider.dhuhr;
            case 'Asr':
              return settingsProvider.asr;
            case 'Maghrib':
              return settingsProvider.maghrib;
            case 'Isha':
              return settingsProvider.isha;
            default:
              return false;
          }
        }

        String getPrayerKey() => entry.key.toLowerCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              if (entry.key == 'Sunrise')
                const SizedBox(width: 48)
              else
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isNotificationEnabled()
                        ? Icons.notifications_active
                        : Icons.notifications_off_outlined,
                    size: 20,
                    color: isNext
                        ? theme.colorScheme.onPrimaryContainer.withOpacity(0.9)
                        : theme.hintColor.withOpacity(0.9),
                  ),
                  onPressed: () {
                    final key = getPrayerKey();
                    final currentValue = isNotificationEnabled();
                    settingsProvider.updateSetting(key, !currentValue);
                  },
                ),
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
