import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../main.dart'; // import for themeNotifier

// Extension to easily convert Iterable<MapEntry<String, String>> to Map<String, String>
extension MapEntryListToMapExtension on Iterable<MapEntry<String, String>> {
  Map<String, String> toMap() => {for (var e in this) e.key: e.value};
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String _city = "Loading...";
  String _country = "";
  String _todayDate = DateFormat("EEE, MMM d").format(DateTime.now());

  Map<String, String> _prayerTimes = {};
  String _nextPrayer = "Loading...";
  String _nextPrayerTime = "";

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCachedPrayerTimes(); // Load cached data first
    _getLocationAndPrayerTimes(); // Fetch live data
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_prayerTimes.isNotEmpty && _nextPrayer != "Loading...") {
        _updateCountdown();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Method to load cached prayer times from SharedPreferences
  Future<void> _loadCachedPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPrayerTimesString = prefs.getString("prayerTimes");
    final savedNextPrayer = prefs.getString("nextPrayer");

    if (savedPrayerTimesString != null && savedNextPrayer != null) {
      try {
        // Manually parse the string representation of the map
        final Map<String, String> times = {};
        // The string is in the format "{Fajr: 05:00 AM, Dhuhr: 12:00 PM, ...}"
        // We need to remove the curly braces and split by ", "
        final cleanedString = savedPrayerTimesString.substring(
          1,
          savedPrayerTimesString.length - 1,
        );
        final entries = cleanedString.split(', ');

        for (var entry in entries) {
          final parts = entry.split(': ');
          if (parts.length >= 2) {
            final key = parts[0];
            // Re-join the rest of the parts in case the time itself contained ": "
            final value = parts.sublist(1).join(': ');
            times[key] = value;
          }
        }

        setState(() {
          _prayerTimes = times;
          _nextPrayer = savedNextPrayer;
        });
      } catch (e) {
        print("Error parsing cached prayer times: $e");
        // If parsing fails, clear potentially corrupted data
        await prefs.remove("prayerTimes");
        await prefs.remove("nextPrayer");
      }
    }
  }

  // Method to save prayer times to SharedPreferences
  Future<void> _savePrayerTimes(
    Map<String, String> times,
    String nextPrayer,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert map to string representation
    await prefs.setString("prayerTimes", times.toString());
    await prefs.setString("nextPrayer", nextPrayer);
  }

  // Future<void> _getLocationAndPrayerTimes() async {
  //   try {
  //     LocationPermission permission = await Geolocator.checkPermission();
  //     if (permission == LocationPermission.denied ||
  //         permission == LocationPermission.deniedForever) {
  //       permission = await Geolocator.requestPermission();
  //     }

  //     if (permission == LocationPermission.whileInUse ||
  //         permission == LocationPermission.always) {
  //       Position position = await Geolocator.getCurrentPosition(
  //         desiredAccuracy: LocationAccuracy.high,
  //       );
  //       List<Placemark> placemarks = await placemarkFromCoordinates(
  //         position.latitude,
  //         position.longitude,
  //       );
  //       if (placemarks.isNotEmpty) {
  //         setState(() {
  //           _city = placemarks.first.locality ?? "Unknown City";
  //           _country = placemarks.first.country ?? "";
  //         });
  //       }
  //       _calculatePrayerTimes(position.latitude, position.longitude);
  //     } else {
  //       setState(() {
  //         _city = "Location Unavailable";
  //         _country = "";
  //       });
  //     }
  //   } catch (e) {
  //     print("Error in _getLocationAndPrayerTimes: $e");
  //     setState(() {
  //       _city = "Location Unavailable";
  //       _country = "";
  //     });
  //   }
  // }
  Future<void> _getLocationAndPrayerTimes() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Instead of using placemarkFromCoordinates (needs internet),
        // just show lat/lng or a fallback name
        setState(() {
          _city = "My Location";
          _country = "";
        });

        // Prayer time calculation works offline
        _calculatePrayerTimes(position.latitude, position.longitude);
      } else {
        setState(() {
          _city = "Location Unavailable";
          _country = "";
        });
      }
    } catch (e) {
      print("Error in _getLocationAndPrayerTimes: $e");
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
      date: now,
      calculationParameters: params,
    );
    final formatter = DateFormat("hh:mm a");

    final fajrLocal = prayerTimes.fajr!.toLocal();
    final dhuhrLocal = prayerTimes.dhuhr!.toLocal();
    final asrLocal = prayerTimes.asr!.toLocal();
    final maghribLocal = prayerTimes.maghrib!.toLocal();
    final ishaLocal = prayerTimes.isha!.toLocal();

    final times = {
      "Fajr": formatter.format(fajrLocal),
      "Dhuhr": formatter.format(dhuhrLocal),
      "Asr": formatter.format(asrLocal),
      "Maghrib": formatter.format(maghribLocal),
      "Isha": formatter.format(ishaLocal),
    };

    DateTime? nextPrayerTimeLocal;
    String nextPrayerName = "Loading...";

    if (now.isBefore(fajrLocal)) {
      nextPrayerName = "Fajr";
      nextPrayerTimeLocal = fajrLocal;
    } else if (now.isBefore(dhuhrLocal)) {
      nextPrayerName = "Dhuhr";
      nextPrayerTimeLocal = dhuhrLocal;
    } else if (now.isBefore(asrLocal)) {
      nextPrayerName = "Asr";
      nextPrayerTimeLocal = asrLocal;
    } else if (now.isBefore(maghribLocal)) {
      nextPrayerName = "Maghrib";
      nextPrayerTimeLocal = maghribLocal;
    } else if (now.isBefore(ishaLocal)) {
      nextPrayerName = "Isha";
      nextPrayerTimeLocal = ishaLocal;
    } else {
      nextPrayerName = "Fajr (Tomorrow)";
      nextPrayerTimeLocal = fajrLocal.add(const Duration(days: 1));
    }

    // Save the newly calculated times and update the state
    _savePrayerTimes(times, nextPrayerName);
    setState(() {
      _prayerTimes = times;
      _nextPrayer = nextPrayerName;
    });
    _updateCountdown(nextPrayerTimeLocal);
  }

  void _updateCountdown([DateTime? nextPrayerTimeLocal]) {
    if (_prayerTimes.isEmpty || _nextPrayer == "Loading...") return;

    final now = DateTime.now();
    DateTime? targetNextPrayerTime;
    String currentNextPrayerName = _nextPrayer;

    // Determine the target time for the next prayer based on current _nextPrayer
    if (currentNextPrayerName == "Fajr") {
      final fajrTime = DateFormat("hh:mm a").parse(_prayerTimes["Fajr"]!);
      targetNextPrayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        fajrTime.hour,
        fajrTime.minute,
        fajrTime.second,
      );
    } else if (currentNextPrayerName == "Dhuhr") {
      final dhuhrTime = DateFormat("hh:mm a").parse(_prayerTimes["Dhuhr"]!);
      targetNextPrayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        dhuhrTime.hour,
        dhuhrTime.minute,
        dhuhrTime.second,
      );
    } else if (currentNextPrayerName == "Asr") {
      final asrTime = DateFormat("hh:mm a").parse(_prayerTimes["Asr"]!);
      targetNextPrayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        asrTime.hour,
        asrTime.minute,
        asrTime.second,
      );
    } else if (currentNextPrayerName == "Maghrib") {
      final maghribTime = DateFormat("hh:mm a").parse(_prayerTimes["Maghrib"]!);
      targetNextPrayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        maghribTime.hour,
        maghribTime.minute,
        maghribTime.second,
      );
    } else if (currentNextPrayerName == "Isha") {
      final ishaTime = DateFormat("hh:mm a").parse(_prayerTimes["Isha"]!);
      targetNextPrayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        ishaTime.hour,
        ishaTime.minute,
        ishaTime.second,
      );
    } else if (currentNextPrayerName == "Fajr (Tomorrow)") {
      final fajrToday = DateFormat("hh:mm a").parse(_prayerTimes["Fajr"]!);
      targetNextPrayerTime = DateTime(
        now.year,
        now.month,
        now.day + 1,
        fajrToday.hour,
        fajrToday.minute,
        fajrToday.second,
      );
    }

    // If the current time is past the calculated next prayer time, update _nextPrayer
    if (targetNextPrayerTime != null && now.isAfter(targetNextPrayerTime)) {
      if (currentNextPrayerName != "Fajr (Tomorrow)") {
        currentNextPrayerName = "Fajr (Tomorrow)";
        final fajrToday = DateFormat("hh:mm a").parse(_prayerTimes["Fajr"]!);
        targetNextPrayerTime = DateTime(
          now.year,
          now.month,
          now.day + 1,
          fajrToday.hour,
          fajrToday.minute,
          fajrToday.second,
        );
        if (_nextPrayer != currentNextPrayerName) {
          setState(() {
            _nextPrayer = currentNextPrayerName;
          });
        }
      }
    }

    // Calculate and update the countdown string
    if (targetNextPrayerTime != null) {
      final duration = targetNextPrayerTime.difference(now);
      final countdown =
          "${duration.inHours.remainder(24).toString().padLeft(2, '0')}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}";
      setState(() {
        _nextPrayerTime = countdown;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
        break;
      case 1: // Media
        Navigator.pushReplacementNamed(context, '/media');
        break;
      case 2: // Prayer
        Navigator.pushReplacementNamed(context, '/prayer');
        break;
      case 3: // Chat Bot
        Navigator.pushReplacementNamed(context, '/Chat Bot');
        break;
      case 4: // Sub Apps
        Navigator.pushReplacementNamed(context, '/subapps');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context); // Use Theme.of(context) directly

    final bool isLive = true;
    final int viewers = 1240;
    final List<Map<String, String>> trending = [
      {"title": "Quran Recitation", "thumbnail": "assets/images/trending1.png"},
      {"title": "Islamic Lecture", "thumbnail": "assets/images/trending2.png"},
      {"title": "Dua Compilation", "thumbnail": "assets/images/trending3.png"},
    ];
    final List<Map<String, String>> news = [
      {
        "title": "Global Relief Efforts for Recent Disaster Intensify",
        "time": "2h ago",
        "image": "assets/images/news1.png",
      },
      {
        "title": "New Mosque Opening in Addis Ababa Next Week",
        "time": "5h ago",
        "image": "assets/images/news2.png",
      },
      {
        "title": "Islamic App Reaches 1 Million Users",
        "time": "1d ago",
        "image": "assets/images/news3.png",
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Hello, Aisha",
          style: TextStyle(
            color: theme.textTheme.bodyLarge!.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none,
              color: theme.iconTheme.color,
              size: size.width * 0.06,
            ),
            onPressed: () => Navigator.pushNamed(context, "/notifications"),
          ),
          IconButton(
            icon: Icon(
              themeNotifier.value == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: theme.iconTheme.color,
              size: size.width * 0.06,
            ),
            onPressed: () {
              setState(() {
                themeNotifier.value = themeNotifier.value == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark;
              });
            },
          ),
          InkWell(
            onTap: () => Navigator.pushNamed(context, "/profile"),
            borderRadius: BorderRadius.circular(50),
            child: const CircleAvatar(
              backgroundImage: AssetImage("assets/images/profile.jpg"),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🎥 Video Banner
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/live'),
              child: Container(
                width: size.width,
                height: size.height * 0.25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/banner.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    if (isLive)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "LIVE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$viewers viewers",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// 💳 Halal Premium
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Halal Premium",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge!.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enjoy ad-free streaming, exclusive content, and 10% off purchases.",
                    style: TextStyle(color: theme.textTheme.bodyLarge!.color),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () =>
                          Navigator.pushNamed(context, "/subscription"),
                      child: const Text(
                        "Manage Subscription",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// 🕌 Prayer Times
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Prayer Times",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge!.color,
                  ),
                ),
                const SizedBox(height: 4),
                if (_nextPrayer != "Loading...")
                  Text(
                    "Next: $_nextPrayer in $_nextPrayerTime",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      (_prayerTimes.isEmpty
                              ? {
                                  "Fajr": "--:--",
                                  "Dhuhr": "--:--",
                                  "Asr": "--:--",
                                  "Maghrib": "--:--",
                                  "Isha": "--:--",
                                }.entries
                              : _prayerTimes.entries)
                          .map((entry) {
                            final prayerName = entry.key;
                            final prayerTime = entry.value;
                            final bool isActive = _nextPrayer.contains(
                              prayerName,
                            );

                            final timeParts = prayerTime.split(" ");
                            final hourMinute = timeParts[0];
                            final amPm = timeParts.length > 1
                                ? timeParts[1]
                                : "";

                            return Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/prayer'),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8, // Adjusted padding
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: isActive
                                        ? Colors.blue[600]
                                        : Theme.of(context).cardColor,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        prayerName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isActive
                                              ? Colors.white
                                              : theme
                                                    .textTheme
                                                    .bodyLarge!
                                                    .color,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        hourMinute,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isActive
                                              ? Colors.white
                                              : theme
                                                    .textTheme
                                                    .bodyLarge!
                                                    .color,
                                        ),
                                      ),
                                      Text(
                                        amPm,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isActive
                                              ? Colors.white
                                              : theme
                                                    .textTheme
                                                    .bodyMedium!
                                                    .color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 📱 Apps Section
            Text(
              "Apps",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge!.color,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAppCard(
                  "assets/images/alfuqan.jpg",
                  "Alfurqan",
                  () => Navigator.pushNamed(context, '/alfuqan'),
                  Theme.of(context).cardColor,
                ),
                const SizedBox(width: 12),
                // Inside your _HomeScreenState class, find the _buildAppCard for Kirbgebeya:
                _buildAppCard(
                  "assets/images/kirbgebeya.png",
                  "Kirbgebeya",
                  () async {
                    final Uri url = Uri.parse("https://kirbgebeya.com/");

                    // For in-app webview, skip canLaunchUrl
                    try {
                      await launchUrl(
                        url,
                        mode: LaunchMode.inAppWebView, // opens inside the app
                      );
                    } catch (e) {
                      print("Error launching URL: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Could not open the link"),
                        ),
                      );
                    }
                  },
                  Theme.of(context).cardColor,
                ),
                const SizedBox(width: 12),
                _buildAppCard(
                  "assets/images/besira.jpg",
                  "Besirah",
                  () => Navigator.pushNamed(context, '/besirah'),
                  Theme.of(context).cardColor,
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔥 Trending
            Text(
              "Trending on Minber TV",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge!.color,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: size.height * 0.25,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trending.length,
                itemBuilder: (context, index) {
                  final item = trending[index];
                  return InkWell(
                    onTap: () => Navigator.pushNamed(context, '/live'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: size.width * 0.65,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).cardColor,
                        image: DecorationImage(
                          image: AssetImage(item["thumbnail"]!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).scaffoldBackgroundColor.withOpacity(0.7),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            item["title"]!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            /// 📰 News
            Text(
              "Latest News & Updates",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: news.length,
              itemBuilder: (context, index) {
                final item = news[index];
                return Card(
                  color: Theme.of(context).cardColor,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      print("News clicked: ${item["title"]}");
                      Navigator.pushNamed(
                        context,
                        '/news_detail',
                        arguments: item,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: AssetImage(
                                "assets/images/news${index + 1}.png",
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          item["title"]!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ),
                        subtitle: Text(
                          item["time"]!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium!.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 24,
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

  Widget _buildAppCard(
    String imagePath,
    String title,
    VoidCallback onTap,
    Color? cardColor,
  ) {
    final size = MediaQuery.of(context).size;
    final double cardWidth = size.width * 0.28;
    final double cardHeight = cardWidth * 1.2;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
