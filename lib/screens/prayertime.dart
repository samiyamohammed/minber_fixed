import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:minber_super_app_new_fixed/services/notification_service.dart';
import '../core/app_colors.dart'; // Assuming this is your color file

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  int _selectedIndex = 2;

  String _city = "Loading...";
  String _country = "";
  String _todayDate = DateFormat("EEE, MMM d").format(DateTime.now());

  Map<String, String> _prayerTimes = {};
  String _nextPrayer = "Loading...";
  String _nextPrayerTime = "";

  // controls for turning on/off the alarm icon for each prayer
  Map<String, bool> _alarmEnabled = {};

  Timer? _timer;

  // Icons for prayers
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
  @override
  void initState() {
    super.initState();
    _getLocation();

    // Schedule the weekly Thursday Salawat notification at 7PM EAT
    NotificationService.scheduleSalawatNotification();

    // This timer updates countdown every second (also triggers rebuild so the header clock updates)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_prayerTimes.isNotEmpty) {
        _updateCountdown();
      } else {
        // still rebuild the time in header for live clock effect
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // After fetching location → calculate times AND schedule notifications
      _calculatePrayerTimes(position.latitude, position.longitude);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

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
    final sunrise = prayerTimes.sunrise!.toLocal();
    final dhuhr = prayerTimes.dhuhr!.toLocal();
    final asr = prayerTimes.asr!.toLocal();
    final maghrib = prayerTimes.maghrib!.toLocal();
    final isha = prayerTimes.isha!.toLocal();

    // Keep insertion order: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha
    final times = {
      "Fajr": formatter.format(fajr),
      "Sunrise": formatter.format(sunrise),
      "Dhuhr": formatter.format(dhuhr),
      "Asr": formatter.format(asr),
      "Maghrib": formatter.format(maghrib),
      "Isha": formatter.format(isha),
    };

    String next = "";
    DateTime? nextTime;

    if (now.isBefore(fajr)) {
      next = "Fajr";
      nextTime = fajr;
    } else if (now.isBefore(dhuhr)) {
      next = "Dhuhr";
      nextTime = dhuhr;
    } else if (now.isBefore(asr)) {
      next = "Asr";
      nextTime = asr;
    } else if (now.isBefore(maghrib)) {
      next = "Maghrib";
      nextTime = maghrib;
    } else if (now.isBefore(isha)) {
      next = "Isha";
      nextTime = isha;
    } else {
      next = "Fajr (Tomorrow)";
      nextTime = fajr.add(const Duration(days: 1));
    }

    setState(() {
      _prayerTimes = times;
      _nextPrayer = next;
      // default alarms on for each available time (you can persist this later)
      _alarmEnabled = {for (var k in times.keys) k: true};
    });

    _updateCountdown();
    // Cancel previous schedules before rescheduling (to avoid duplicates)
    // Optional: implement clear function in NotificationService if needed

    NotificationService.schedulePrayerNotification(
      id: "fajr",
      title: "Fajr Prayer",
      body:
          "It is time for Fajr prayer. Begin your day with remembrance of Allah.",
      scheduledTime: fajr,
    );

    NotificationService.schedulePrayerNotification(
      id: "dhuhr",
      title: "Dhuhr Prayer",
      body: "It is time for Dhuhr prayer. Take a moment to remember Allah.",
      scheduledTime: dhuhr,
    );

    NotificationService.schedulePrayerNotification(
      id: "asr",
      title: "Asr Prayer",
      body: "It is time for Asr prayer. Stand for your afternoon prayer.",
      scheduledTime: asr,
    );

    NotificationService.schedulePrayerNotification(
      id: "maghrib",
      title: "Maghrib Prayer",
      body: "It is time for Maghrib prayer. Break your fast and pray.",
      scheduledTime: maghrib,
    );

    NotificationService.schedulePrayerNotification(
      id: "isha",
      title: "Isha Prayer",
      body:
          "It is time for Isha prayer. End your day with remembrance of Allah.",
      scheduledTime: isha,
    );
  }

  void _updateCountdown() {
    if (_prayerTimes.isEmpty || _nextPrayer == "Loading...") {
      return;
    }

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

      setState(() {
        _nextPrayerTime = countdown;
      });
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
        Navigator.pushReplacementNamed(context, '/chatBot');
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
      ),
      body: Column(
        children: [
          // HEADER WITH BACKGROUND IMAGE + OVERLAY
          Stack(
            children: [
              Container(
                // Reduced height of the banner
                height: size.height * 0.25, // Adjusted from 0.32
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/mosque.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                // Reduced height of the banner overlay
                height: size.height * 0.25, // Adjusted from 0.32
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
                  vertical: size.height * 0.02, // Reduced padding
                  horizontal: size.width * 0.05,
                ),
                child: Column(
                  children: [
                    // Location row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: size.width * 0.045, // Reduced icon size
                        ),
                        SizedBox(width: 6),
                        Text(
                          "$_city, $_country",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * 0.035, // Reduced text size
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: size.height * 0.01), // Reduced spacing
                    // Big clock (updates because timer triggers rebuild)
                    Text(
                      DateFormat("hh:mm a").format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.08, // Reduced font size
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: size.height * 0.006), // Reduced spacing
                    // Next prayer countdown
                    if (_nextPrayerTime.isNotEmpty)
                      Text(
                        "$_nextPrayer in ($_nextPrayerTime)",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: size.width * 0.035, // Reduced text size
                        ),
                      ),

                    SizedBox(height: size.height * 0.01), // Reduced spacing
                    // Date & hijri small pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4, // Reduced padding
                        horizontal: 10, // Reduced padding
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${DateFormat("EEE, MMM d, yyyy").format(DateTime.now())} | Rabi' Al-Thani 8 1447",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: size.width * 0.03, // Reduced font size
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // PRAYER TIMES + OTHER TOOLS in a scrollable area
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(size.width * 0.04),
              children: [
                // Title
                Text(
                  "Today's Prayer Times",
                  style: TextStyle(
                    fontSize: size.width * 0.04, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: size.height * 0.015), // Reduced spacing
                // If no times yet show a loader / placeholder
                if (_prayerTimes.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: size.height * 0.06, // Reduced padding
                      ),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(
                            height: size.height * 0.015,
                          ), // Reduced spacing
                          Text(
                            "Calculating prayer times...",
                            style: TextStyle(color: theme.hintColor),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Prayer cards
                ..._prayerTimes.entries.map((entry) {
                  final isNext = entry.key == _nextPrayer;
                  final alarmOn = _alarmEnabled[entry.key] ?? false;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // moderate radius
                      side: isNext
                          ? BorderSide(
                              color: AppColors.primary,
                              width: 1.2, // slightly thicker border
                            )
                          : BorderSide(color: Colors.transparent),
                    ),
                    elevation: 1.2, // light shadow
                    margin: EdgeInsets.only(
                      bottom: size.height * 0.008, // slightly more margin
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: size.height * 0.009, // balanced padding
                        horizontal: size.width * 0.03,
                      ),
                      leading: Text(
                        _prayerIcons[entry.key] ?? "🕋",
                        style: TextStyle(
                          fontSize: size.width * 0.055, // slightly bigger icon
                        ),
                      ),
                      title: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: size.width * 0.038, // balanced font size
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
                              fontSize:
                                  size.width * 0.035, // slightly bigger font
                              fontWeight: FontWeight.bold,
                              color: isNext
                                  ? AppColors.primary
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          SizedBox(
                            width: size.width * 0.022, // moderate spacing
                          ),
                          // alarm toggle (icon)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _alarmEnabled[entry.key] = !alarmOn;
                              });
                              // TODO: hook real notifications here if needed
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: EdgeInsets.all(
                                size.width * 0.007, // moderate padding
                              ),
                              child: Icon(
                                alarmOn
                                    ? Icons.notifications_active
                                    : Icons.notifications_none,
                                color: alarmOn
                                    ? AppColors.primary
                                    : theme.hintColor,
                                size:
                                    size.width * 0.042, // slightly bigger icon
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                SizedBox(height: size.height * 0.02), // Reduced spacing
                // Other Tools header
                Text(
                  "Other Tools",
                  style: TextStyle(
                    fontSize: size.width * 0.04, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: size.height * 0.015), // Reduced spacing
                // Grid of tools (Hijri Calendar & Qibla Compass)
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
                            // Icon inside circle with primary color
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2973C7), // primary color
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

                SizedBox(height: size.height * 0.03), // Reduced spacing
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
        selectedFontSize: size.width * 0.028, // Reduced font size
        unselectedFontSize: size.width * 0.028, // Reduced font size
        iconSize: size.width * 0.055, // Reduced icon size
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
