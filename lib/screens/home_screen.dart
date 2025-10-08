// import 'dart:async';
// import 'dart:convert'; // For json decoding cached data
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:adhan_dart/adhan_dart.dart';
// import 'package:minber_super_app_new_fixed/core/theme_notifier.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../core/app_colors.dart';
// import '../main.dart' as main;
// // In homescreen.dart
// import 'package:provider/provider.dart';
// import '../providers/user_provider.dart'; // import for themeNotifier with prefix

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;
//   Timer? _timer;

//   // --- State Variables ---
//   String _city = "Loading...";
//   String _nextPrayerName = "Loading...";
//   String _nextPrayerCountdown = "--:--:--";

//   // OPTIMIZED: Store actual DateTime objects for fast calculations
//   Map<String, DateTime> _prayerTimes = {};
//   // Store formatted strings separately for UI display
//   Map<String, String> _formattedPrayerTimes = {};

//   @override
//   void initState() {
//     super.initState();
//     // This now happens much faster
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<UserProvider>(context, listen: false).fetchUser();
//     });
//     _initializePrayerTimes();
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (_prayerTimes.isNotEmpty) {
//         _updateCountdown();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   Future<void> _initializePrayerTimes() async {
//     // 1. Attempt to load from cache for an instant UI update
//     final bool loadedFromCache = await _loadCachedPrayerTimes();
//     if (loadedFromCache) {
//       _updateNextPrayerAndCountdown(); // Immediately calculate countdown from cached data
//     }
//     // 2. Fetch fresh location and prayer times in the background
//     await _getLocationAndPrayerTimes();
//   }

//   // --- Prayer Time Logic (Refactored for Performance) ---

//   Future<bool> _loadCachedPrayerTimes() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final savedTimesJson = prefs.getString("prayerTimesIso");
//       if (savedTimesJson == null) return false;

//       final decodedTimes = jsonDecode(savedTimesJson) as Map<String, dynamic>;
//       final now = DateTime.now();

//       // Check if the cached data is for today
//       final cacheDateStr = decodedTimes['date'];
//       if (cacheDateStr == null ||
//           DateFormat('yyyy-MM-dd').format(DateTime.parse(cacheDateStr)) !=
//               DateFormat('yyyy-MM-dd').format(now)) {
//         return false; // Stale data from a previous day
//       }

//       setState(() {
//         _prayerTimes = {
//           'Fajr': DateTime.parse(decodedTimes['Fajr']),
//           'Dhuhr': DateTime.parse(decodedTimes['Dhuhr']),
//           'Asr': DateTime.parse(decodedTimes['Asr']),
//           'Maghrib': DateTime.parse(decodedTimes['Maghrib']),
//           'Isha': DateTime.parse(decodedTimes['Isha']),
//         };
//         _formatPrayerTimesForUI();
//         _city = prefs.getString('locationCity') ?? "My Location";
//       });
//       print("✅ Successfully loaded prayer times from cache.");
//       return true;
//     } catch (e) {
//       print("Error loading cached prayer times: $e");
//       return false;
//     }
//   }

//   Future<void> _savePrayerTimes() async {
//     final prefs = await SharedPreferences.getInstance();
//     // Store as a JSON string with a date for validation
//     final timesToSave = {
//       'date': DateTime.now().toIso8601String(),
//       'Fajr': _prayerTimes['Fajr']!.toIso8601String(),
//       'Dhuhr': _prayerTimes['Dhuhr']!.toIso8601String(),
//       'Asr': _prayerTimes['Asr']!.toIso8601String(),
//       'Maghrib': _prayerTimes['Maghrib']!.toIso8601String(),
//       'Isha': _prayerTimes['Isha']!.toIso8601String(),
//     };
//     await prefs.setString("prayerTimesIso", jsonEncode(timesToSave));
//     await prefs.setString("locationCity", _city);
//     print("✅ Saved prayer times to cache.");
//   }

//   Future<void> _getLocationAndPrayerTimes() async {
//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }

//       if (permission == LocationPermission.whileInUse ||
//           permission == LocationPermission.always) {
//         Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high,
//         );
//         _calculatePrayerTimes(position.latitude, position.longitude);
//       } else {
//         setState(() => _city = "Location needed");
//       }
//     } catch (e) {
//       print("Error getting location: $e");
//       setState(() => _city = "Location error");
//     }
//   }

//   void _calculatePrayerTimes(double lat, double lng) {
//     final coordinates = Coordinates(lat, lng);
//     final params = CalculationMethod.muslimWorldLeague()..madhab = Madhab.shafi;
//     final prayerTimesData = PrayerTimes(
//       coordinates: coordinates,
//       date: DateTime.now(),
//       calculationParameters: params,
//     );

//     setState(() {
//       _prayerTimes = {
//         'Fajr': prayerTimesData.fajr!.toLocal(),
//         'Dhuhr': prayerTimesData.dhuhr!.toLocal(),
//         'Asr': prayerTimesData.asr!.toLocal(),
//         'Maghrib': prayerTimesData.maghrib!.toLocal(),
//         'Isha': prayerTimesData.isha!.toLocal(),
//       };
//       _formatPrayerTimesForUI();
//       _city = "My Location"; // Update location name
//       _updateNextPrayerAndCountdown(); // Calculate next prayer
//       _savePrayerTimes(); // Save the new data
//     });
//   }

//   void _formatPrayerTimesForUI() {
//     final formatter = DateFormat("hh:mm a");
//     _formattedPrayerTimes = _prayerTimes.map(
//       (key, value) => MapEntry(key, formatter.format(value)),
//     );
//   }

//   void _updateNextPrayerAndCountdown() {
//     final now = DateTime.now();
//     String nextPrayer = "Fajr (Tomorrow)";
//     DateTime? nextPrayerDateTime;

//     for (var entry in _prayerTimes.entries) {
//       if (now.isBefore(entry.value)) {
//         nextPrayer = entry.key;
//         nextPrayerDateTime = entry.value;
//         break;
//       }
//     }

//     if (nextPrayerDateTime == null) {
//       nextPrayerDateTime = _prayerTimes['Fajr']?.add(const Duration(days: 1));
//     }

//     setState(() {
//       _nextPrayerName = nextPrayer;
//     });

//     // This is separated to be called every second by the timer
//     _updateCountdown();
//   }

//   void _updateCountdown() {
//     if (_prayerTimes.isEmpty) return;

//     final now = DateTime.now();
//     DateTime? targetTime;

//     if (_nextPrayerName.contains('Tomorrow')) {
//       targetTime = _prayerTimes['Fajr']?.add(const Duration(days: 1));
//     } else {
//       targetTime = _prayerTimes[_nextPrayerName];
//     }

//     if (targetTime == null) return;

//     if (now.isAfter(targetTime)) {
//       // Time for next prayer has passed, recalculate which one is next
//       _updateNextPrayerAndCountdown();
//       return;
//     }

//     final duration = targetTime.difference(now);
//     final countdown =
//         "${duration.inHours.remainder(24).toString().padLeft(2, '0')}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}";

//     if (mounted) {
//       setState(() => _nextPrayerCountdown = countdown);
//     }
//   }

//   void _onItemTapped(int index) {
//     if (index == _selectedIndex) return;
//     setState(() => _selectedIndex = index);
//     switch (index) {
//       case 1:
//         Navigator.pushReplacementNamed(context, '/media');
//         break;
//       case 2:
//         Navigator.pushReplacementNamed(context, '/prayer');
//         break;
//       case 3:
//         Navigator.pushReplacementNamed(context, '/Chat Bot');
//         break;
//       case 4:
//         Navigator.pushReplacementNamed(context, '/subapps');
//         break;
//     }
//   }

//   // --- BUILD METHOD ---

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final theme = Theme.of(context);

//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHeader(theme, size),
//               const SizedBox(height: 16),

//               _buildVideoBanner(size),
//               const SizedBox(height: 16),

//               _buildHalalPremium(theme),
//               const SizedBox(height: 16),

//               _buildPrayerTimesSection(theme),
//               const SizedBox(height: 16),

//               _buildAppsSection(theme),
//               const SizedBox(height: 16),

//               _buildTrendingSection(size, theme),
//               const SizedBox(height: 16),

//               _buildNewsSection(theme),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: _buildBottomNavigationBar(theme),
//     );
//   }

//   // --- WIDGET BUILDERS ---

//   Widget _buildHeader(ThemeData theme, Size size) {
//     return Consumer<UserProvider>(
//       builder: (context, userProvider, child) {
//         Widget headerContent;

//         if (userProvider.isLoading && userProvider.user == null) {
//           // --- LOADING STATE ---
//           headerContent = Row(
//             children: [
//               CircleAvatar(backgroundColor: theme.cardColor),
//               const SizedBox(width: 12),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     width: 120,
//                     height: 20,
//                     decoration: BoxDecoration(
//                       color: theme.cardColor,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Container(
//                     width: 80,
//                     height: 14,
//                     decoration: BoxDecoration(
//                       color: theme.cardColor,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           );
//         } else if (userProvider.user != null) {
//           // --- DATA LOADED STATE ---
//           headerContent = Row(
//             children: [
//               InkWell(
//                 onTap: () => Navigator.pushNamed(context, "/profile"),
//                 borderRadius: BorderRadius.circular(50),
//                 child: CircleAvatar(
//                   backgroundColor: AppColors.primary.withOpacity(0.1),
//                   child: Text(
//                     userProvider.user!.username.isNotEmpty
//                         ? userProvider.user!.username[0].toUpperCase()
//                         : '?',
//                     style: TextStyle(
//                       color: AppColors.primary,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 20,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Hello, ${userProvider.user!.username}",
//                     style: theme.textTheme.titleLarge?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text("Welcome Back!", style: theme.textTheme.bodyMedium),
//                 ],
//               ),
//             ],
//           );
//         } else {
//           // --- ERROR / NOT LOGGED IN STATE ---
//           headerContent = Row(
//             children: [
//               InkWell(
//                 onTap: () => Navigator.pushNamed(context, "/profile"),
//                 borderRadius: BorderRadius.circular(50),
//                 child: CircleAvatar(
//                   backgroundColor: theme.cardColor,
//                   child: const Icon(Icons.person, color: Colors.grey),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text("Welcome", style: theme.textTheme.titleLarge),
//             ],
//           );
//         }

//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Row(
//             children: [
//               headerContent,
//               const Spacer(),
//               IconButton(
//                 icon: Icon(
//                   Icons.notifications_none,
//                   color: theme.iconTheme.color,
//                   size: size.width * 0.065,
//                 ),
//                 onPressed: () => Navigator.pushNamed(context, "/notifications"),
//               ),
//               ValueListenableBuilder<ThemeMode>(
//                 valueListenable: main.themeNotifier,
//                 builder: (context, currentMode, child) {
//                   return IconButton(
//                     icon: Icon(
//                       currentMode == ThemeMode.dark
//                           ? Icons.light_mode_outlined
//                           : Icons.dark_mode_outlined,
//                       color: theme.iconTheme.color,
//                       size: size.width * 0.065,
//                     ),
//                     onPressed: () {
//                       final newMode = currentMode == ThemeMode.dark
//                           ? ThemeMode.light
//                           : ThemeMode.dark;
//                       main.themeNotifier.value = newMode;
//                       saveThemePreference(newMode);
//                     },
//                   );
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildVideoBanner(Size size) {
//     return GestureDetector(
//       onTap: () => Navigator.pushNamed(context, '/live'),
//       child: Container(
//         width: size.width,
//         height: size.height * 0.25,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           image: const DecorationImage(
//             image: AssetImage("assets/images/banner.png"),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: Stack(
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 gradient: LinearGradient(
//                   colors: [Colors.black.withOpacity(0.6), Colors.transparent],
//                   begin: Alignment.bottomCenter,
//                   end: Alignment.topCenter,
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 12,
//               left: 12,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 5,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   "LIVE",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ),
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.play_arrow, color: Colors.white, size: 28),
//                     const SizedBox(width: 8),
//                     const Icon(Icons.volume_up, color: Colors.white, size: 24),
//                     const Spacer(),
//                     const Icon(Icons.fullscreen, color: Colors.white, size: 28),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHalalPremium(ThemeData theme) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.primary.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Halal Premium",
//             style: theme.textTheme.titleMedium?.copyWith(
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Enjoy ad-free streaming, exclusive content, and 10% off purchases.",
//             style: theme.textTheme.bodyMedium,
//           ),
//           const SizedBox(height: 12),
//           Align(
//             alignment: Alignment.centerRight,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppColors.primary,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               onPressed: () => Navigator.pushNamed(context, "/subscription"),
//               child: const Text(
//                 "Manage Subscription",
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPrayerTimesSection(ThemeData theme) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("Prayer Times", style: theme.textTheme.titleLarge),
//         const SizedBox(height: 4),
//         if (_nextPrayerName != "Loading...")
//           Text(
//             "Next: $_nextPrayerName in $_nextPrayerCountdown",
//             style: TextStyle(fontSize: 14, color: AppColors.primary),
//           ),
//         const SizedBox(height: 12),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children:
//               (_formattedPrayerTimes.isEmpty
//                       ? {
//                           "Fajr": "--:--",
//                           "Dhuhr": "--:--",
//                           "Asr": "--:--",
//                           "Maghrib": "--:--",
//                           "Isha": "--:--",
//                         }
//                       : _formattedPrayerTimes)
//                   .entries
//                   .map((entry) {
//                     final prayerName = entry.key;
//                     final prayerTime = entry.value;
//                     final bool isActive = _nextPrayerName.contains(prayerName);

//                     return Expanded(
//                       child: Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 4),
//                         padding: const EdgeInsets.symmetric(vertical: 10),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(12),
//                           color: isActive ? AppColors.primary : theme.cardColor,
//                           boxShadow: isActive
//                               ? [
//                                   BoxShadow(
//                                     color: AppColors.primary.withOpacity(0.3),
//                                     blurRadius: 8,
//                                     offset: const Offset(0, 4),
//                                   ),
//                                 ]
//                               : [],
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               prayerName,
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 color: isActive
//                                     ? Colors.white
//                                     : theme.textTheme.bodyLarge!.color,
//                               ),
//                             ),
//                             const SizedBox(height: 6),
//                             Text(
//                               prayerTime,
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 15,
//                                 color: isActive
//                                     ? Colors.white
//                                     : theme.textTheme.bodyLarge!.color,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   })
//                   .toList(),
//         ),
//       ],
//     );
//   }

//   Widget _buildAppsSection(ThemeData theme) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("Apps", style: theme.textTheme.titleLarge),
//         const SizedBox(height: 12),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             // FIXED: Passing theme object
//             _buildAppCard(
//               theme,
//               "assets/images/alfuqan.jpg",
//               "Alfurqan",
//               () => Navigator.pushNamed(context, '/alfuqan'),
//               theme.cardColor,
//             ),
//             _buildAppCard(
//               theme,
//               "assets/images/kirbgebeya.png",
//               "Kirbgebeya",
//               () async {
//                 final Uri url = Uri.parse("https://kirbgebeya.com/");
//                 if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Could not open the link")),
//                   );
//                 }
//               },
//               theme.cardColor,
//             ),
//             _buildAppCard(
//               theme,
//               "assets/images/besira.jpg",
//               "Besirah",
//               () => Navigator.pushNamed(context, '/besirah'),
//               theme.cardColor,
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildTrendingSection(Size size, ThemeData theme) {
//     final List<Map<String, String>> trending = [
//       {
//         "title": "Quran Recitation by Famous Qari",
//         "thumbnail": "assets/images/trending1.png",
//       },
//       {
//         "title": "Weekly Islamic Lecture Series",
//         "thumbnail": "assets/images/trending2.png",
//       },
//       {
//         "title": "Collection of Powerful Dua",
//         "thumbnail": "assets/images/trending3.png",
//       },
//     ];
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("Trending on Minber TV", style: theme.textTheme.titleLarge),
//         const SizedBox(height: 8),
//         SizedBox(
//           height: size.height * 0.22,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: trending.length,
//             itemBuilder: (context, index) {
//               final item = trending[index];
//               return InkWell(
//                 onTap: () => Navigator.pushNamed(context, '/live'),
//                 borderRadius: BorderRadius.circular(12),
//                 child: Container(
//                   width: size.width * 0.7,
//                   margin: const EdgeInsets.only(right: 12),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(12),
//                     image: DecorationImage(
//                       image: AssetImage(item["thumbnail"]!),
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   child: Align(
//                     alignment: Alignment.bottomLeft,
//                     child: Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.5),
//                         borderRadius: const BorderRadius.only(
//                           bottomLeft: Radius.circular(12),
//                           bottomRight: Radius.circular(12),
//                         ),
//                       ),
//                       child: Text(
//                         item["title"]!,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildNewsSection(ThemeData theme) {
//     final List<Map<String, String>> news = [
//       {
//         "title": "Global Relief Efforts Intensify for Recent Disaster",
//         "time": "2h ago",
//         "image": "assets/images/news1.png",
//       },
//       {
//         "title": "New Grand Mosque Opening in Addis Ababa Next Week",
//         "time": "5h ago",
//         "image": "assets/images/news2.png",
//       },
//       {
//         "title": "Minber Super App Reaches 1 Million Downloads",
//         "time": "1d ago",
//         "image": "assets/images/news3.png",
//       },
//     ];
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text("Latest News & Updates", style: theme.textTheme.titleLarge),
//         ListView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: news.length,
//           itemBuilder: (context, index) {
//             final item = news[index];
//             return Card(
//               color: theme.cardColor,
//               margin: const EdgeInsets.symmetric(vertical: 6),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(12),
//                 onTap: () => Navigator.pushNamed(
//                   context,
//                   '/news_detail',
//                   arguments: item,
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(10.0),
//                   child: Row(
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.asset(
//                           item['image']!,
//                           width: 70,
//                           height: 70,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               item["title"]!,
//                               style: theme.textTheme.bodyLarge?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               item["time"]!,
//                               style: theme.textTheme.bodySmall,
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   // **** FIX IS HERE ****
//   // Added 'ThemeData theme' as the first parameter
//   Widget _buildAppCard(
//     ThemeData theme,
//     String imagePath,
//     String title,
//     VoidCallback onTap,
//     Color? cardColor,
//   ) {
//     return Expanded(
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Column(
//           children: [
//             Container(
//               height: 80,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 image: DecorationImage(
//                   image: AssetImage(imagePath),
//                   fit: BoxFit.cover,
//                 ),
//                 // Now 'theme' is defined and can be used here
//                 boxShadow: [
//                   BoxShadow(
//                     color: theme.shadowColor.withOpacity(0.1),
//                     blurRadius: 5,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               title,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   BottomNavigationBar _buildBottomNavigationBar(ThemeData theme) {
//     return BottomNavigationBar(
//       currentIndex: _selectedIndex,
//       onTap: _onItemTapped,
//       selectedItemColor: AppColors.primary,
//       unselectedItemColor: Colors.grey,
//       type: BottomNavigationBarType.fixed,
//       backgroundColor: theme.bottomAppBarTheme.color,
//       elevation: 5,
//       items: const [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.home_outlined),
//           activeIcon: Icon(Icons.home),
//           label: "Home",
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.tv_outlined),
//           activeIcon: Icon(Icons.tv),
//           label: "Media",
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.mosque_outlined),
//           activeIcon: Icon(Icons.mosque),
//           label: "Prayer",
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.chat_bubble_outline),
//           activeIcon: Icon(Icons.chat_bubble),
//           label: "Chat Bot",
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.apps_outlined),
//           activeIcon: Icon(Icons.apps),
//           label: "Sub Apps",
//         ),
//       ],
//     );
//   }
// }
import 'dart:async';
import 'dart:convert'; // For json decoding cached data
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:minber_super_app_new_fixed/core/theme_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../main.dart' as main;
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../widgets/app_drawer.dart'; // Import your drawer

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

  String _city = "Loading...";
  String _nextPrayerName = "Loading...";
  String _nextPrayerCountdown = "--:--:--";

  // We only need the DateTime objects now, formatting is done in the build method
  Map<String, DateTime> _prayerTimes = {};

  @override
  void initState() {
    super.initState();
    _initializeBannerPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUser();
    });
    _initializePrayerTimes();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_prayerTimes.isNotEmpty) {
        _updateCountdown();
      }
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
    }
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
        _city = prefs.getString('locationCity') ?? "My Location";
      });
      print("✅ Successfully loaded prayer times from cache.");
      return true;
    } catch (e) {
      print("Error loading cached prayer times: $e");
      return false;
    }
  }

  Future<void> _savePrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final timesToSave = {
      'date': DateTime.now().toIso8601String(),
      'Fajr': _prayerTimes['Fajr']!.toIso8601String(),
      'Dhuhr': _prayerTimes['Dhuhr']!.toIso8601String(),
      'Asr': _prayerTimes['Asr']!.toIso8601String(),
      'Maghrib': _prayerTimes['Maghrib']!.toIso8601String(),
      'Isha': _prayerTimes['Isha']!.toIso8601String(),
    };
    await prefs.setString("prayerTimesIso", jsonEncode(timesToSave));
    await prefs.setString("locationCity", _city);
    print("✅ Saved prayer times to cache.");
  }

  Future<void> _getLocationAndPrayerTimes() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _calculatePrayerTimes(position.latitude, position.longitude);
      } else {
        setState(() => _city = "Location needed");
      }
    } catch (e) {
      print("Error getting location: $e");
      setState(() => _city = "Location error");
    }
  }

  void _calculatePrayerTimes(double lat, double lng) {
    final coordinates = Coordinates(lat, lng);
    final params = CalculationMethod.muslimWorldLeague()..madhab = Madhab.shafi;
    final prayerTimesData = PrayerTimes(
      coordinates: coordinates,
      date: DateTime.now(),
      calculationParameters: params,
    );

    setState(() {
      _prayerTimes = {
        'Fajr': prayerTimesData.fajr!.toLocal(),
        'Dhuhr': prayerTimesData.dhuhr!.toLocal(),
        'Asr': prayerTimesData.asr!.toLocal(),
        'Maghrib': prayerTimesData.maghrib!.toLocal(),
        'Isha': prayerTimesData.isha!.toLocal(),
      };
      _city = "My Location";
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

    if (nextPrayerDateTime == null) {
      nextPrayerDateTime = _prayerTimes['Fajr']?.add(const Duration(days: 1));
    }

    setState(() {
      _nextPrayerName = nextPrayer;
    });

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

    if (mounted) {
      setState(() => _nextPrayerCountdown = countdown);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 1:
        Navigator.pushReplacementNamed(context, '/media');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/prayer');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/Chat Bot');
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
      // --- THE FINAL FIX IS HERE ---
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        // 1. Style the title directly
        title: Text(
          'Minber',
          style: TextStyle(
            color: theme.brightness == Brightness.light
                ? Colors.black
                : Colors.white,
          ),
        ),
        // 2. Style the icons (like the drawer icon) directly
        iconTheme: IconThemeData(
          color: theme.brightness == Brightness.light
              ? Colors.black
              : Colors.white,
        ),
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVideoBanner(size),
              const SizedBox(height: 16),
              _buildHalalPremium(theme),
              const SizedBox(height: 16),
              _buildPrayerTimesSection(theme),
              const SizedBox(height: 16),
              _buildAppsSection(theme),
              const SizedBox(height: 16),
              _buildTrendingSection(size, theme),
              const SizedBox(height: 16),
              _buildNewsSection(theme),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(theme),
    );
  }

  Widget _buildVideoBanner(Size size) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/live'),
      child: Container(
        width: size.width,
        height: size.height * 0.25,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _bannerChewieController != null &&
                      _bannerChewieController!
                          .videoPlayerController.value.isInitialized
                  ? Chewie(controller: _bannerChewieController!)
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
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
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHalalPremium(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Halal Premium",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enjoy ad-free streaming, exclusive content, and 10% off purchases.",
            style: theme.textTheme.bodyMedium,
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
              onPressed: () => Navigator.pushNamed(context, "/subscription"),
              child: const Text(
                "Manage Subscription",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesSection(ThemeData theme) {
    final timeFormatter = DateFormat("hh:mm");
    final periodFormatter = DateFormat("a");
    const prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Prayer Times", style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        if (_nextPrayerName != "Loading...")
          Text(
            "Next: $_nextPrayerName in $_nextPrayerCountdown",
            style: TextStyle(fontSize: 14, color: AppColors.primary),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: prayerOrder.map((prayerName) {
            final bool isActive = _nextPrayerName.contains(prayerName);
            final prayerDateTime = _prayerTimes[prayerName];

            if (prayerDateTime == null) {
              return _buildPrayerTimeColumn(
                theme: theme,
                prayerName: prayerName,
                time: "--:--",
                period: "",
                isActive: false,
              );
            }

            final timeString = timeFormatter.format(prayerDateTime);
            final periodString = periodFormatter.format(prayerDateTime);

            return _buildPrayerTimeColumn(
              theme: theme,
              prayerName: prayerName,
              time: timeString,
              period: periodString,
              isActive: isActive,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrayerTimeColumn({
    required ThemeData theme,
    required String prayerName,
    required String time,
    required String period,
    required bool isActive,
  }) {
    final textColumn = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prayerName,
            style: TextStyle(
                color:
                    isActive ? Colors.white : theme.textTheme.bodyMedium?.color,
                fontSize: 14)),
        const SizedBox(height: 4),
        Text(time,
            style: TextStyle(
                color:
                    isActive ? Colors.white : theme.textTheme.bodyLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(period.toUpperCase(),
            style: TextStyle(
                color: isActive ? Colors.white70 : Colors.grey, fontSize: 12)),
      ],
    );

    return Expanded(
      child: isActive
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: textColumn,
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: textColumn,
            ),
    );
  }

  Widget _buildAppsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Apps", style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAppCard(
              theme,
              "assets/images/alfuqan.jpg",
              "Alfurqan",
              () => Navigator.pushNamed(context, '/alfuqan'),
              theme.cardColor,
            ),
            _buildAppCard(
              theme,
              "assets/images/kirbgebeya.png",
              "Kirbgebeya",
              () async {
                final Uri url = Uri.parse("https://kirbgebeya.com/");
                if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Could not open the link")),
                  );
                }
              },
              theme.cardColor,
            ),
            _buildAppCard(
              theme,
              "assets/images/besira.jpg",
              "Besirah",
              () => Navigator.pushNamed(context, '/besirah'),
              theme.cardColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendingSection(Size size, ThemeData theme) {
    final List<Map<String, String>> trending = [
      {
        "title": "Quran Recitation by Famous Qari",
        "thumbnail": "assets/images/trending1.png",
      },
      {
        "title": "Weekly Islamic Lecture Series",
        "thumbnail": "assets/images/trending2.png",
      },
      {
        "title": "Collection of Powerful Dua",
        "thumbnail": "assets/images/trending3.png",
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Trending on Minber TV", style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: size.height * 0.22,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: trending.length,
            itemBuilder: (context, index) {
              final item = trending[index];
              return InkWell(
                onTap: () => Navigator.pushNamed(context, '/live'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: size.width * 0.7,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: AssetImage(item["thumbnail"]!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        item["title"]!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewsSection(ThemeData theme) {
    final List<Map<String, String>> news = [
      {
        "title": "Global Relief Efforts Intensify for Recent Disaster",
        "time": "2h ago",
        "image": "assets/images/news1.png",
      },
      {
        "title": "New Grand Mosque Opening in Addis Ababa Next Week",
        "time": "5h ago",
        "image": "assets/images/news2.png",
      },
      {
        "title": "Minber Super App Reaches 1 Million Downloads",
        "time": "1d ago",
        "image": "assets/images/news3.png",
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Latest News & Updates", style: theme.textTheme.titleLarge),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: news.length,
          itemBuilder: (context, index) {
            final item = news[index];
            return Card(
              color: theme.cardColor,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/news_detail',
                  arguments: item,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          item['image']!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["title"]!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item["time"]!,
                              style: theme.textTheme.bodySmall,
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
        ),
      ],
    );
  }

  Widget _buildAppCard(
    ThemeData theme,
    String imagePath,
    String title,
    VoidCallback onTap,
    Color? cardColor,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(ThemeData theme) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      backgroundColor: theme.bottomAppBarTheme.color,
      elevation: 5,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.tv_outlined),
          activeIcon: Icon(Icons.tv),
          label: "Media",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.mosque_outlined),
          activeIcon: Icon(Icons.mosque),
          label: "Prayer",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: "Chat Bot",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.apps_outlined),
          activeIcon: Icon(Icons.apps),
          label: "Sub Apps",
        ),
      ],
    );
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

    if (mounted) {
      setState(() {});
    }
  }
}
