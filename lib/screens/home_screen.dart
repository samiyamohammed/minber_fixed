// lib/screens/home_screen.dart (Fully Updated & Ready to Paste)
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:shimmer/shimmer.dart';

import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Timer? _timer;

  late VideoPlayerController _bannerVideoController;
  ChewieController? _bannerChewieController;
  final String streamUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

  String _nextPrayerName = "";
  String _nextPrayerCountdown = "--:--:--";
  Map<String, DateTime> _prayerTimes = {};
  bool _isLoadingPrayerTimes = true;

  // --- CORE LOGIC (UNCHANGED) ---

  @override
  void initState() {
    super.initState();
    _initializeBannerPlayer();
    _initializePrayerTimes();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_prayerTimes.isNotEmpty) _updateCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerVideoController.dispose();
    _bannerChewieController?.dispose();
    super.dispose();
  }

  Future<void> _initializePrayerTimes() async {
    final bool loadedFromCache = await _loadCachedPrayerTimes();
    if (loadedFromCache) {
      _updateNextPrayerAndCountdown();
      setState(() => _isLoadingPrayerTimes = false);
    }
    await _getLocationAndPrayerTimes();
  }

  Future<void> _refreshData() async {
    await _getLocationAndPrayerTimes();
  }

  Future<bool> _loadCachedPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTimesJson = prefs.getString("prayerTimesIso");
      if (savedTimesJson == null) return false;
      final decodedTimes = jsonDecode(savedTimesJson) as Map<String, dynamic>;
      final now = DateTime.now();
      final cacheDateStr = decodedTimes['date'];
      if (cacheDateStr == null ||
          DateFormat('yyyy-MM-dd').format(DateTime.parse(cacheDateStr)) !=
              DateFormat('yyyy-MM-dd').format(now)) {
        return false;
      }
      setState(() {
        _prayerTimes = {
          'Fajr': DateTime.parse(decodedTimes['Fajr']),
          'Dhuhr': DateTime.parse(decodedTimes['Dhuhr']),
          'Asr': DateTime.parse(decodedTimes['Asr']),
          'Maghrib': DateTime.parse(decodedTimes['Maghrib']),
          'Isha': DateTime.parse(decodedTimes['Isha']),
        };
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _savePrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final timesToSave = _prayerTimes
        .map((key, value) => MapEntry(key, value.toIso8601String()));
    timesToSave['date'] = DateTime.now().toIso8601String();
    await prefs.setString("prayerTimesIso", jsonEncode(timesToSave));
  }

  Future<void> _getLocationAndPrayerTimes() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        _calculatePrayerTimes(position.latitude, position.longitude);
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted && _isLoadingPrayerTimes) {
        setState(() => _isLoadingPrayerTimes = false);
      }
    }
  }

  void _calculatePrayerTimes(double lat, double lng) {
    final prayerTimesData = PrayerTimes(
        coordinates: Coordinates(lat, lng),
        date: DateTime.now(),
        calculationParameters: CalculationMethod.muslimWorldLeague()
          ..madhab = Madhab.shafi);
    setState(() {
      _prayerTimes = {
        'Fajr': prayerTimesData.fajr!.toLocal(),
        'Dhuhr': prayerTimesData.dhuhr!.toLocal(),
        'Asr': prayerTimesData.asr!.toLocal(),
        'Maghrib': prayerTimesData.maghrib!.toLocal(),
        'Isha': prayerTimesData.isha!.toLocal(),
      };
      _updateNextPrayerAndCountdown();
      _savePrayerTimes();
    });
  }

  void _updateNextPrayerAndCountdown() {
    final now = DateTime.now();
    String nextPrayer = "Fajr (Tomorrow)";
    DateTime? nextPrayerDateTime;
    for (var entry in _prayerTimes.entries) {
      if (now.isBefore(entry.value)) {
        nextPrayer = entry.key;
        nextPrayerDateTime = entry.value;
        break;
      }
    }
    if (nextPrayerDateTime == null)
      nextPrayerDateTime = _prayerTimes['Fajr']?.add(const Duration(days: 1));
    setState(() => _nextPrayerName = nextPrayer);
    _updateCountdown();
  }

  void _updateCountdown() {
    if (_prayerTimes.isEmpty) return;
    final now = DateTime.now();
    DateTime? targetTime;
    if (_nextPrayerName.contains('Tomorrow')) {
      targetTime = _prayerTimes['Fajr']?.add(const Duration(days: 1));
    } else {
      targetTime = _prayerTimes[_nextPrayerName];
    }
    if (targetTime == null) return;
    if (now.isAfter(targetTime)) {
      _updateNextPrayerAndCountdown();
      return;
    }
    final duration = targetTime.difference(now);
    final countdown =
        "${duration.inHours.remainder(24).toString().padLeft(2, '0')}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    if (mounted) setState(() => _nextPrayerCountdown = countdown);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    String routeName = '';
    switch (index) {
      case 0:
        break;
      case 1:
        routeName = '/media';
        break;
      case 2:
        routeName = '/prayer';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minber TV'),
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVideoBanner(context),
              const SizedBox(height: 24),
              _buildHalalPremium(theme),
              const SizedBox(height: 24),
              _buildPrayerTimesSection(theme),
              const SizedBox(height: 24),
              _buildSectionHeader(theme, "Explore Our Apps", () {}),
              const SizedBox(height: 12),
              _buildAppsSection(theme),
              const SizedBox(height: 24),
              _buildSectionHeader(theme, "Trending on Minber", () {}),
              const SizedBox(height: 12),
              _buildTrendingSection(context, theme),
              const SizedBox(height: 24),
              _buildSectionHeader(theme, "Latest News", () {}),
              const SizedBox(height: 12),
              _buildNewsSection(theme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(theme),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildVideoBanner(BuildContext context) {
    // ... This widget remains the same ...
    return GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/live'),
        child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                    color: Colors.black,
                    child: Stack(fit: StackFit.expand, children: [
                      if (_bannerChewieController != null &&
                          _bannerChewieController!
                              .videoPlayerController.value.isInitialized)
                        Chewie(controller: _bannerChewieController!)
                      else
                        const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white)),
                      Container(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent
                          ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.center))),
                      Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Text("LIVE",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))))
                    ])))));
  }

  Widget _buildHalalPremium(ThemeData theme) {
    // ... This widget remains the same ...
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text("Halal Premium",
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Enjoy ad-free streaming, exclusive content, and more.",
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.hintColor))
              ])),
          const SizedBox(width: 12),
          ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, "/subscription"),
              child: const Text("Upgrade"))
        ]));
  }

  Widget _buildPrayerTimesSection(ThemeData theme) {
    const prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    // ✅ CORRECTION: Create separate formatters for time and period
    final timeFormatter = DateFormat("h:mm");
    final periodFormatter = DateFormat("a");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isLoadingPrayerTimes)
          Text("Next: $_nextPrayerName in $_nextPrayerCountdown",
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold))
        else
          Text("Next Prayer",
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.hintColor, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _isLoadingPrayerTimes
            ? _buildPrayerTimesShimmer(theme)
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: prayerOrder.map((prayerName) {
                  final isActive = _nextPrayerName.contains(prayerName);
                  final prayerDateTime = _prayerTimes[prayerName];
                  return _buildPrayerTimeColumn(
                    theme: theme,
                    prayerName: prayerName,
                    // ✅ CORRECTION: Pass separate time and period strings
                    time: prayerDateTime != null
                        ? timeFormatter.format(prayerDateTime)
                        : "--:--",
                    period: prayerDateTime != null
                        ? periodFormatter.format(prayerDateTime)
                        : "",
                    isActive: isActive,
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildPrayerTimesShimmer(ThemeData theme) {
    // ... This widget remains the same ...
    return Shimmer.fromColors(
        baseColor: theme.splashColor,
        highlightColor: theme.cardColor,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
                5,
                (_) => Expanded(
                        child: Column(children: [
                      Container(
                          width: 40,
                          height: 12,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 6)),
                      Container(width: 50, height: 16, color: Colors.white)
                    ])))));
  }

  Widget _buildPrayerTimeColumn(
      {required ThemeData theme,
      required String prayerName,
      required String time,
      required String period,
      required bool isActive}) {
    // ✅ CORRECTION: Rebuilt the column to handle separate time and period
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: isActive
            ? BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12))
            : null, // Using a softer corner radius
        child: Column(
          children: [
            Text(prayerName,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: isActive
                        ? theme.colorScheme.onPrimary.withOpacity(0.8)
                        : theme.hintColor)),
            const SizedBox(height: 4),
            Text(time,
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onBackground)),
            const SizedBox(height: 2),
            Text(period.toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: isActive
                        ? theme.colorScheme.onPrimary.withOpacity(0.8)
                        : theme.hintColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      ThemeData theme, String title, VoidCallback onViewAll) {
    // ... This widget remains the same ...
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
      TextButton(onPressed: onViewAll, child: const Text("View All"))
    ]);
  }

  Widget _buildAppsSection(ThemeData theme) {
    // ... This widget remains the same ...
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _buildAppCard(theme, "assets/images/alfuqan.jpg", "Alfurqan", () {}),
      const SizedBox(width: 12),
      _buildAppCard(theme, "assets/images/kirbgebeya.png", "Kirbgebeya",
          () async {
        final url = Uri.parse("https://kirbgebeya.com/");
        if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {}
      }),
      const SizedBox(width: 12),
      _buildAppCard(theme, "assets/images/besira.jpg", "Besirah", () {})
    ]);
  }

  Widget _buildAppCard(
      ThemeData theme, String imagePath, String title, VoidCallback onTap) {
    // ... This widget remains the same ...
    return Expanded(
        child: GestureDetector(
            onTap: onTap,
            child: Column(children: [
              AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(imagePath, fit: BoxFit.cover))),
              const SizedBox(height: 8),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold))
            ])));
  }

  Widget _buildTrendingSection(BuildContext context, ThemeData theme) {
    // ... This widget remains the same ...
    return SizedBox(
        height: MediaQuery.of(context).size.width * 0.4,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) => Container(
                width: MediaQuery.of(context).size.width * 0.7,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                        image: AssetImage(
                            "assets/images/trending${index + 1}.png"),
                        fit: BoxFit.cover)))));
  }

  Widget _buildNewsSection(ThemeData theme) {
    // ✅ CORRECTION: Data has been updated with placeholder titles and times
    final List<Map<String, String>> news = [
      {
        "title": "Global Relief Efforts Intensify for Recent Disaster",
        "time": "2h ago",
        "image": "assets/images/news1.png"
      },
      {
        "title": "New Grand Mosque Opening in Addis Ababa Next Week",
        "time": "5h ago",
        "image": "assets/images/news2.png"
      },
      {
        "title": "Minber App Reaches 1 Million Downloads",
        "time": "1d ago",
        "image": "assets/images/news3.png"
      },
    ];
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: news.length,
      itemBuilder: (context, index) {
        final item = news[index];
        return Card(
          elevation: 0,
          color: theme.cardColor,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(item['image']!,
                          width: 70, height: 70, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  // ✅ CORRECTION: Added an Expanded Column to hold the placeholder text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["title"]!,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item["time"]!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(ThemeData theme) {
    // ... This widget remains the same ...
    return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.unselectedWidgetColor,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.cardColor,
        elevation: 5,
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
              icon: Icon(Icons.apps_outlined),
              activeIcon: Icon(Icons.apps),
              label: "Sub Apps")
        ]);
  }

  Future<void> _initializeBannerPlayer() async {
    _bannerVideoController =
        VideoPlayerController.networkUrl(Uri.parse(streamUrl));
    await _bannerVideoController.initialize();
    await _bannerVideoController.setVolume(0.0);
    _bannerChewieController = ChewieController(
      videoPlayerController: _bannerVideoController,
      autoPlay: true,
      isLive: true,
      showControls: false,
      looping: false,
    );
    if (mounted) setState(() {});
  }
}
