import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:logger/logger.dart';
import 'package:minber_super_app_new_fixed/services/notification_service.dart';
// Add the hijri package import
import 'package:hijri/hijri_calendar.dart';
import '../core/app_colors.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  int _selectedIndex = 2;

  String _city = "Loading...";
  String _country = "";
  String _todayDate = DateFormat("EEE, MMM d").format(DateTime.now());

  Map<String, String> _prayerTimes = {};
  String _nextPrayer = "Loading...";
  String _nextPrayerTime = "";

  Map<String, bool> _alarmEnabled = {};
  Timer? _timer;

  final Map<String, String> _prayerIcons = {
    "Fajr": "🌅",
    "Sunrise": "🌄",
    "Dhuhr": "🌞",
    "Asr": "🌤",
    "Maghrib": "🌇",
    "Isha": "🌙",
  };

  final List<Map<String, String>> _otherTools = [
    {'name': 'Hijri Calendar', 'icon': '📅'},
    {'name': 'Qibla Compass', 'icon': '🧭'},
    {'name': 'Dua & Dhikr', 'icon': '🤲'},
  ];

  @override
  void initState() {
    super.initState();
    logger.i("PrayerTimesPage initState: Initializing...");
    _getLocationAndCalculateTimesForUI(); // Renamed for clarity

    // Scheduling is now handled centrally in main.dart and the background task.

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_prayerTimes.isNotEmpty) {
        _updateCountdown();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    logger.w("PrayerTimesPage disposed.");
    _timer?.cancel();
    super.dispose();
  }

  // This function now ONLY gets location and calculates times for DISPLAY purposes.
  Future<void> _getLocationAndCalculateTimesForUI() async {
    logger.i("Attempting to get device location for UI...");
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      logger.d(
        "📍 Position found for UI: ${position.latitude}, ${position.longitude}",
      );

      // This calculates times just to show them on the screen
      _calculatePrayerTimesForUI(position.latitude, position.longitude);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() {
          _city = placemarks.first.locality ?? "Unknown City";
          _country = placemarks.first.country ?? "";
          logger.i("📍 UI Location set to: $_city, $_country");
        });
      }
    } catch (e, s) {
      logger.e("❌ Failed to get location for UI", error: e, stackTrace: s);
      setState(() {
        _city = "Location Unavailable";
        _country = "";
      });
    }
  }

  // This function now ONLY calculates times for the UI. It does NOT schedule notifications.
  void _calculatePrayerTimesForUI(double lat, double lng) {
    logger.i("Calculating prayer times for UI display only...");
    final coordinates = Coordinates(lat, lng);
    final params = CalculationMethod.muslimWorldLeague();
    params.madhab = Madhab.shafi;
    final now = DateTime.now();
    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: DateTime.now(),
      calculationParameters: params,
    );
    final formatter = DateFormat("hh:mm a");

    final fajr = prayerTimes.fajr!.toLocal();
    final dhuhr = prayerTimes.dhuhr!.toLocal();
    final asr = prayerTimes.asr!.toLocal();
    final maghrib = prayerTimes.maghrib!.toLocal();
    final isha = prayerTimes.isha!.toLocal();

    final times = {
      "Fajr": formatter.format(fajr),
      "Sunrise": formatter.format(prayerTimes.sunrise!.toLocal()),
      "Dhuhr": formatter.format(dhuhr),
      "Asr": formatter.format(asr),
      "Maghrib": formatter.format(maghrib),
      "Isha": formatter.format(isha),
    };
    logger.d("Calculated Prayer Times for UI (Map): $times");

    String next = "";
    if (now.isBefore(fajr))
      next = "Fajr";
    else if (now.isBefore(dhuhr))
      next = "Dhuhr";
    else if (now.isBefore(asr))
      next = "Asr";
    else if (now.isBefore(maghrib))
      next = "Maghrib";
    else if (now.isBefore(isha))
      next = "Isha";
    else
      next = "Fajr (Tomorrow)";

    logger.i("⏰ Next prayer for UI determined: $next");

    setState(() {
      _prayerTimes = times;
      _nextPrayer = next;
      _alarmEnabled = {for (var k in times.keys) k: true};
    });

    _updateCountdown();
    logger.i("UI prayer times have been updated.");
  }

  void _updateCountdown() {
    if (_prayerTimes.isEmpty || _nextPrayer == "Loading...") return;
    final now = DateTime.now();
    DateTime? nextTime;
    String nextPrayerName = _nextPrayer;
    if (nextPrayerName == "Fajr") {
      final t = DateFormat("hh:mm a").parse(_prayerTimes["Fajr"]!);
      nextTime = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    } else if (nextPrayerName == "Dhuhr") {
      final t = DateFormat("hh:mm a").parse(_prayerTimes["Dhuhr"]!);
      nextTime = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    } else if (nextPrayerName == "Asr") {
      final t = DateFormat("hh:mm a").parse(_prayerTimes["Asr"]!);
      nextTime = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    } else if (nextPrayerName == "Maghrib") {
      final t = DateFormat("hh:mm a").parse(_prayerTimes["Maghrib"]!);
      nextTime = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    } else if (nextPrayerName == "Isha") {
      final t = DateFormat("hh:mm a").parse(_prayerTimes["Isha"]!);
      nextTime = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    } else if (nextPrayerName == "Fajr (Tomorrow)") {
      final t = DateFormat("hh:mm a").parse(_prayerTimes["Fajr"]!);
      nextTime = DateTime(now.year, now.month, now.day + 1, t.hour, t.minute);
    }
    if (nextTime != null) {
      final currentTimeToday = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second,
      );
      if (currentTimeToday.isAfter(nextTime)) {
        if (nextPrayerName != "Fajr (Tomorrow)") {
          nextPrayerName = "Fajr (Tomorrow)";
          nextTime = DateFormat("hh:mm a").parse(_prayerTimes["Fajr"]!);
          nextTime = DateTime(
            now.year,
            now.month,
            now.day + 1,
            nextTime.hour,
            nextTime.minute,
          );
        }
      }
      final duration = nextTime.difference(currentTimeToday);
      final countdown =
          "${duration.inHours.remainder(24).toString().padLeft(2, '0')}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}";
      if (mounted) setState(() => _nextPrayerTime = countdown);
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/media');
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/chatbot');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/subapps');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    // Get the current Hijri date and format it
    final hijriDate = HijriCalendar.now();
    final formattedHijriDate = hijriDate.toFormat("MMMM d, yyyy");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Prayer Times",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor ?? theme.primaryColorLight,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.notification_add_outlined),
            tooltip: 'Send Test Notification',
            onPressed: () {
              logger.i("🔔 Test Notification button pressed.");
              NotificationService.schedulePrayerNotification(
                id: "test_notification",
                title: "Test Notification",
                body: "If you see this, your notification service is working!",
                scheduledTime: DateTime.now().add(const Duration(seconds: 5)),
                repeatDaily: false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Test notification scheduled in 5 seconds."),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: size.height * 0.25,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/mosque.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: size.height * 0.25,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.45),
                      AppColors.primary.withOpacity(0.45),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: size.height * 0.02,
                  horizontal: size.width * 0.05,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: size.width * 0.045,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "$_city, $_country",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * 0.035,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.01),
                    Text(
                      DateFormat("hh:mm a").format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.08,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: size.height * 0.006),
                    if (_nextPrayerTime.isNotEmpty)
                      Text(
                        "$_nextPrayer in ($_nextPrayerTime)",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: size.width * 0.035,
                        ),
                      ),
                    SizedBox(height: size.height * 0.01),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        // Updated to use the dynamic Hijri date
                        "${DateFormat("EEE, MMM d, yyyy").format(DateTime.now())} | $formattedHijriDate",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: size.width * 0.03,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(size.width * 0.04),
              children: [
                Text(
                  "Today's Prayer Times",
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                if (_prayerTimes.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: size.height * 0.06,
                      ),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: size.height * 0.015),
                          Text(
                            "Calculating prayer times...",
                            style: TextStyle(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ..._prayerTimes.entries.map((entry) {
                  final isNext = entry.key == _nextPrayer;
                  final alarmOn = _alarmEnabled[entry.key] ?? false;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: isNext
                          ? BorderSide(color: AppColors.primary, width: 1.2)
                          : BorderSide(color: Colors.transparent),
                    ),
                    elevation: 1.2,
                    margin: EdgeInsets.only(bottom: size.height * 0.008),
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: size.height * 0.009,
                        horizontal: size.width * 0.03,
                      ),
                      leading: Text(
                        _prayerIcons[entry.key] ?? "🕋",
                        style: TextStyle(fontSize: size.width * 0.055),
                      ),
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: size.width * 0.038,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.value,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: size.width * 0.035,
                              fontWeight: FontWeight.bold,
                              color: isNext
                                  ? AppColors.primary
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          SizedBox(width: size.width * 0.022),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _alarmEnabled[entry.key] = !alarmOn;
                              });
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: EdgeInsets.all(size.width * 0.007),
                              child: Icon(
                                alarmOn
                                    ? Icons.notifications_active
                                    : Icons.notifications_none,
                                color: alarmOn
                                    ? AppColors.primary
                                    : theme.hintColor,
                                size: size.width * 0.042,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: size.height * 0.02),
                Text(
                  "Other Tools",
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: size.width * 0.04,
                    mainAxisSpacing: size.height * 0.02,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _otherTools.length,
                  itemBuilder: (context, index) {
                    final tool = _otherTools[index];

                    return GestureDetector(
                      onTap: () {
                        if (tool['name'] == 'Hijri Calendar') {
                          Navigator.pushNamed(context, '/hijri-calendar');
                        } else if (tool['name'] == 'Qibla Compass') {
                          Navigator.pushNamed(context, '/qibla-compass');
                        } else if (tool['name'] == 'Dua & Dhikr') {
                          Navigator.pushNamed(context, '/dua-dhikr');
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(2, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2973C7),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                tool['icon']!,
                                style: TextStyle(fontSize: size.width * 0.08),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tool['name']!,
                              style: TextStyle(
                                fontSize: size.width * 0.037,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: size.height * 0.03),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: theme.unselectedWidgetColor,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: size.width * 0.028,
        unselectedFontSize: size.width * 0.028,
        iconSize: size.width * 0.055,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: "Media"),
          BottomNavigationBarItem(icon: Icon(Icons.mosque), label: "Prayer"),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: "Chat Bot",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Sub Apps"),
        ],
      ),
    );
  }
}
