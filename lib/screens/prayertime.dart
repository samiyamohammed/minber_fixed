// lib/screens/prayer_times_page.dart (Fully Updated & Ready to Paste)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shimmer/shimmer.dart'; // ✅ UI/UX UPDATE: Import for loading animation

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  int _selectedIndex = 2; // For BottomNavBar
  bool _isLoading = true; // To control shimmer effect

  String _city = "Loading...";
  String _country = "";

  Map<String, DateTime> _prayerTimesDateTimes =
      {}; // Store DateTime objects for accurate countdown
  String _nextPrayer = "Loading...";
  String _nextPrayerCountdown = "--:--:--";
  Timer? _timer;

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
    _initializePage();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_prayerTimesDateTimes.isNotEmpty) _updateCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _getLocationAndCalculateTimes();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _getLocationAndCalculateTimes() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _calculatePrayerTimes(position.latitude, position.longitude);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        setState(() {
          _city = placemarks.first.locality ?? "Unknown City";
          _country = placemarks.first.country ?? "";
        });
      }
    } catch (e) {
      setState(() {
        _city = "Location Unavailable";
        _country = "";
      });
    }
  }

  void _calculatePrayerTimes(double lat, double lng) {
    final prayerTimesData = PrayerTimes(
        coordinates: Coordinates(lat, lng),
        date: DateTime.now(),
        calculationParameters: CalculationMethod.muslimWorldLeague()
          ..madhab = Madhab.shafi);
    setState(() {
      _prayerTimesDateTimes = {
        "Fajr": prayerTimesData.fajr!.toLocal(),
        "Sunrise": prayerTimesData.sunrise!.toLocal(),
        "Dhuhr": prayerTimesData.dhuhr!.toLocal(),
        "Asr": prayerTimesData.asr!.toLocal(),
        "Maghrib": prayerTimesData.maghrib!.toLocal(),
        "Isha": prayerTimesData.isha!.toLocal(),
      };
      _updateNextPrayerAndCountdown();
    });
  }

  void _updateNextPrayerAndCountdown() {
    final now = DateTime.now();
    String nextPrayer = "Fajr (Tomorrow)";
    for (var entry in _prayerTimesDateTimes.entries) {
      if (now.isBefore(entry.value)) {
        nextPrayer = entry.key;
        break;
      }
    }
    setState(() => _nextPrayer = nextPrayer);
    _updateCountdown();
  }

  void _updateCountdown() {
    if (_prayerTimesDateTimes.isEmpty) return;
    final now = DateTime.now();
    DateTime? targetTime;
    if (_nextPrayer.contains('Tomorrow')) {
      targetTime = _prayerTimesDateTimes['Fajr']?.add(const Duration(days: 1));
    } else {
      targetTime = _prayerTimesDateTimes[_nextPrayer];
    }
    if (targetTime == null) return;
    if (now.isAfter(targetTime)) {
      _updateNextPrayerAndCountdown(); // Recalculate next prayer if time has passed
      return;
    }
    final duration = targetTime.difference(now);
    final countdown =
        "${duration.inHours.remainder(24).toString().padLeft(2, '0')}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    if (mounted) setState(() => _nextPrayerCountdown = countdown);
  }

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
    if (routeName.isNotEmpty)
      Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: _isLoading
                ? const _PrayerListShimmer()
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildPrayerList(theme),
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

  Widget _buildHeader(ThemeData theme) {
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
        // ✅ UI/UX UPDATE: Immersive gradient overlay
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
                  Icon(Icons.location_on, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text("$_city, $_country",
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w500))
                ]),
                const SizedBox(height: 8),
                Text(_nextPrayer,
                    style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (_nextPrayerCountdown.isNotEmpty)
                  Text("in $_nextPrayerCountdown",
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

  Widget _buildPrayerList(ThemeData theme) {
    return Column(
      children: _prayerTimesDateTimes.entries.map((entry) {
        final isNext = entry.key == _nextPrayer;
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
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
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
