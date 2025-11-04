// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';

// import 'package:adhan_dart/adhan_dart.dart';
// import 'package:better_player_plus/better_player_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:minber/main.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// import '../core/app_colors.dart';
// import '../models/video_model.dart';
// import '../widgets/animated_list_item.dart';
// import '../widgets/app_drawer.dart';
// import '../widgets/drawer_indicator.dart';
// import '../widgets/embedded_web_screen.dart';
// import 'trending_see_all_screen.dart';
// import 'video_player_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen>
//     with WidgetsBindingObserver, RouteAware {
//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   int _selectedIndex = 0;
//   Timer? _timer;
//   Timer? _autoRefreshTimer;

//   BetterPlayerController? _bannerPlayerController;
//   bool _isBannerLoading = true;
//   bool _hasBannerError = false;
//   bool _isMuted = true;
//   final String streamUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

//   // ✅ 1. DYNAMIC ASPECT RATIO STATE
//   // This will hold the video's true aspect ratio. Default to 16:9 to avoid initial errors.
//   double _bannerAspectRatio = 16 / 9;

//   String _nextPrayerName = "";
//   String _nextPrayerCountdown = "--:--:--";
//   Map<String, DateTime> _prayerTimes = {};
//   bool _isLoadingPrayerTimes = true;
//   List<dynamic>? _trendingVideos;
//   List<dynamic>? _newsArticles;
//   String? _trendingError;
//   String? _newsError;
//   static const _trendingCacheKey = 'home_trending_cache';
//   static const _newsCacheKey = 'home_news_cache';
//   static const _trendingTimestampKey = 'home_trending_timestamp';
//   static const _newsTimestampKey = 'home_news_timestamp';
//   static const _cacheValidityMinutes = 5;
//   final String _trendingApiUrl = 'http://msa.merkuz.com:3636/trending';
//   final String _newsApiUrl = 'http://msa.merkuz.com:3636/news';
//   final String _apiBaseUrl = 'http://msa.merkuz.com:3636';

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     _initializeBannerPlayer();
//     _initializePrayerTimes();
//     _loadDataWithCache();

//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (_prayerTimes.isNotEmpty) _updateCountdown();
//     });

//     _autoRefreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
//       _refreshData();
//     });
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     routeObserver.subscribe(this, ModalRoute.of(context)!);
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     if (state == AppLifecycleState.resumed) {
//       _bannerPlayerController?.play();
//       _refreshData();
//     } else if (state == AppLifecycleState.paused) {
//       _bannerPlayerController?.pause();
//     }
//   }

//   @override
//   void dispose() {
//     _autoRefreshTimer?.cancel();
//     _timer?.cancel();
//     WidgetsBinding.instance.removeObserver(this);
//     routeObserver.unsubscribe(this);
//     _bannerPlayerController?.dispose();
//     _bannerPlayerController = null;
//     super.dispose();
//   }

//   @override
//   void didPushNext() {
//     _bannerPlayerController?.pause();
//   }

//   @override
//   void didPopNext() {
//     _bannerPlayerController?.play();
//   }

//   Future<void> _initializeBannerPlayer() async {
//     if (mounted) {
//       setState(() {
//         _isBannerLoading = true;
//         _hasBannerError = false;
//       });
//     }

//     _bannerPlayerController?.dispose();

//     BetterPlayerDataSource dataSource = BetterPlayerDataSource(
//       BetterPlayerDataSourceType.network,
//       streamUrl,
//       liveStream: true,
//       notificationConfiguration:
//           const BetterPlayerNotificationConfiguration(showNotification: false),
//     );

//     _bannerPlayerController = BetterPlayerController(
//       const BetterPlayerConfiguration(
//         autoPlay: true,
//         looping: true,
//         // Use contain, as the parent AspectRatio widget will handle the sizing perfectly.
//         fit: BoxFit.contain,
//         controlsConfiguration: BetterPlayerControlsConfiguration(
//           showControls: false,
//         ),
//         handleLifecycle: true,
//       ),
//       betterPlayerDataSource: dataSource,
//     );

//     _bannerPlayerController!.setVolume(0.0);

//     _bannerPlayerController!.addEventsListener((BetterPlayerEvent event) {
//       if (!mounted) return;

//       // ✅ 2. DETECT AND UPDATE THE ASPECT RATIO
//       // This is the core of the dynamic resizing logic.
//       if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
//         final videoController = _bannerPlayerController!.videoPlayerController;
//         if (videoController != null && videoController.value.initialized) {
//           final double newAspectRatio = videoController.value.aspectRatio;
//           // Trigger a rebuild ONLY if the aspect ratio is valid and has changed.
//           if (newAspectRatio > 0 && newAspectRatio != _bannerAspectRatio) {
//             setState(() {
//               _bannerAspectRatio = newAspectRatio;
//             });
//           }
//         }
//       }

//       switch (event.betterPlayerEventType) {
//         case BetterPlayerEventType.initialized:
//         case BetterPlayerEventType.bufferingEnd:
//           setState(() {
//             _isBannerLoading = false;
//             _hasBannerError = false;
//           });
//           break;
//         case BetterPlayerEventType.exception:
//           setState(() {
//             _isBannerLoading = false;
//             _hasBannerError = true;
//           });
//           break;
//         case BetterPlayerEventType.bufferingStart:
//           setState(() => _isBannerLoading = true);
//           break;
//         default:
//           break;
//       }
//     });
//   }

//   // ... (The rest of your code remains exactly the same) ...

//   void _reloadBannerStream() {
//     _initializeBannerPlayer();
//   }

//   void _toggleMute() {
//     if (mounted) {
//       setState(() {
//         _isMuted = !_isMuted;
//       });
//       _bannerPlayerController?.setVolume(_isMuted ? 0.0 : 1.0);
//     }
//   }

//   void _navigateToLivePage() async {
//     await _bannerPlayerController?.pause();
//     Navigator.pushNamed(context, '/live').then((_) {
//       if (mounted) {
//         Future.delayed(const Duration(milliseconds: 500), () {
//           _bannerPlayerController?.play();
//         });
//       }
//     });
//   }

//   Future<void> _loadDataWithCache() async {
//     final prefs = await SharedPreferences.getInstance();
//     final lastTrendingTime = prefs.getInt(_trendingTimestampKey) ?? 0;
//     final now = DateTime.now().millisecondsSinceEpoch;
//     final shouldUseTrendingCache =
//         (now - lastTrendingTime) < (_cacheValidityMinutes * 60 * 1000);
//     if (shouldUseTrendingCache && mounted) {
//       final cachedTrending = prefs.getString(_trendingCacheKey);
//       if (cachedTrending != null) {
//         setState(() => _trendingVideos = json.decode(cachedTrending));
//       }
//     } else {
//       await prefs.remove(_trendingCacheKey);
//     }
//     final lastNewsTime = prefs.getInt(_newsTimestampKey) ?? 0;
//     final shouldUseNewsCache =
//         (now - lastNewsTime) < (_cacheValidityMinutes * 60 * 1000);
//     if (shouldUseNewsCache && mounted) {
//       final cachedNews = prefs.getString(_newsCacheKey);
//       if (cachedNews != null) {
//         setState(() => _newsArticles = json.decode(cachedNews));
//       }
//     } else {
//       await prefs.remove(_newsCacheKey);
//     }
//     await _fetchTrendingVideos();
//     await _fetchNewsArticles();
//   }

//   Future<void> _refreshData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_trendingCacheKey);
//     await prefs.remove(_newsCacheKey);
//     await prefs.remove(_trendingTimestampKey);
//     await prefs.remove(_newsTimestampKey);
//     if (mounted) {
//       setState(() {
//         _trendingVideos = null;
//         _newsArticles = null;
//         _trendingError = null;
//         _newsError = null;
//       });
//     }
//     await Future.wait([
//       _getLocationAndPrayerTimes(),
//       _fetchTrendingVideos(forceRefresh: true),
//       _fetchNewsArticles(forceRefresh: true),
//     ]);
//   }

//   Future<void> _fetchTrendingVideos({bool forceRefresh = false}) async {
//     try {
//       final response = await http.get(Uri.parse(_trendingApiUrl));
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString(_trendingCacheKey, response.body);
//         await prefs.setInt(
//             _trendingTimestampKey, DateTime.now().millisecondsSinceEpoch);
//         if (mounted) {
//           setState(() {
//             _trendingVideos = data;
//             _trendingError = null;
//           });
//         }
//       } else {
//         throw Exception('Failed to load trending videos');
//       }
//     } catch (e) {
//       print("Trending fetch error: $e");
//       if (mounted && (_trendingVideos == null || _trendingVideos!.isEmpty)) {
//         setState(() => _trendingError = e.toString());
//       }
//     }
//   }

//   Future<void> _fetchNewsArticles({bool forceRefresh = false}) async {
//     try {
//       final response = await http.get(Uri.parse(_newsApiUrl));
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString(_newsCacheKey, response.body);
//         await prefs.setInt(
//             _newsTimestampKey, DateTime.now().millisecondsSinceEpoch);
//         if (mounted) {
//           setState(() {
//             _newsArticles = data;
//             _newsError = null;
//           });
//         }
//       } else {
//         throw Exception('Failed to load news articles');
//       }
//     } catch (e) {
//       print("News fetch error: $e");
//       if (mounted && (_newsArticles == null || _newsArticles!.isEmpty)) {
//         setState(() => _newsError = e.toString());
//       }
//     }
//   }

//   Future<void> _initializePrayerTimes() async {
//     final bool loadedFromCache = await _loadCachedPrayerTimes();
//     if (loadedFromCache) {
//       _updateNextPrayerAndCountdown();
//       if (mounted) setState(() => _isLoadingPrayerTimes = false);
//     }
//     await _getLocationAndPrayerTimes();
//   }

//   Future<bool> _loadCachedPrayerTimes() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final savedTimesJson = prefs.getString("prayerTimesIso");
//       if (savedTimesJson == null) return false;
//       final decodedTimes = jsonDecode(savedTimesJson) as Map<String, dynamic>;
//       final now = DateTime.now();
//       final cacheDateStr = decodedTimes['date'];
//       if (cacheDateStr == null ||
//           DateFormat('yyyy-MM-dd').format(DateTime.parse(cacheDateStr)) !=
//               DateFormat('yyyy-MM-dd').format(now)) {
//         return false;
//       }
//       if (mounted) {
//         setState(() {
//           _prayerTimes = {
//             'Fajr': DateTime.parse(decodedTimes['Fajr']),
//             'Dhuhr': DateTime.parse(decodedTimes['Dhuhr']),
//             'Asr': DateTime.parse(decodedTimes['Asr']),
//             'Maghrib': DateTime.parse(decodedTimes['Maghrib']),
//             'Isha': DateTime.parse(decodedTimes['Isha']),
//           };
//         });
//       }
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }

//   Future<void> _savePrayerTimes() async {
//     final prefs = await SharedPreferences.getInstance();
//     final timesToSave = _prayerTimes
//         .map((key, value) => MapEntry(key, value.toIso8601String()));
//     timesToSave['date'] = DateTime.now().toIso8601String();
//     await prefs.setString("prayerTimesIso", jsonEncode(timesToSave));
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
//             desiredAccuracy: LocationAccuracy.high);
//         _calculatePrayerTimes(position.latitude, position.longitude);
//       }
//     } catch (e) {
//       // Handle error
//     } finally {
//       if (mounted && _isLoadingPrayerTimes) {
//         setState(() => _isLoadingPrayerTimes = false);
//       }
//     }
//   }

//   void _calculatePrayerTimes(double lat, double lng) {
//     final prayerTimesData = PrayerTimes(
//       coordinates: Coordinates(lat, lng),
//       date: DateTime.now(),
//       calculationParameters: CalculationMethod.muslimWorldLeague()
//         ..madhab = Madhab.shafi,
//     );
//     if (mounted) {
//       setState(() {
//         _prayerTimes = {
//           'Fajr': prayerTimesData.fajr!.toLocal(),
//           'Dhuhr': prayerTimesData.dhuhr!.toLocal(),
//           'Asr': prayerTimesData.asr!.toLocal(),
//           'Maghrib': prayerTimesData.maghrib!.toLocal(),
//           'Isha': prayerTimesData.isha!.toLocal(),
//         };
//         _updateNextPrayerAndCountdown();
//         _savePrayerTimes();
//       });
//     }
//   }

//   void _updateNextPrayerAndCountdown() {
//     final now = DateTime.now();
//     String nextPrayer = "Fajr (Tomorrow)";
//     DateTime? nextPrayerDateTime;
//     final prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
//     for (var prayerName in prayerOrder) {
//       final prayerTime = _prayerTimes[prayerName];
//       if (prayerTime != null && now.isBefore(prayerTime)) {
//         nextPrayer = prayerName;
//         nextPrayerDateTime = prayerTime;
//         break;
//       }
//     }
//     if (nextPrayerDateTime == null) {
//       nextPrayerDateTime = _prayerTimes['Fajr']?.add(const Duration(days: 1));
//     }
//     if (mounted) setState(() => _nextPrayerName = nextPrayer);
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
//       _updateNextPrayerAndCountdown();
//       return;
//     }
//     final duration = targetTime.difference(now);
//     final countdown =
//         "${duration.inHours.remainder(24).toString().padLeft(2, '0')}:${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}";
//     if (mounted) setState(() => _nextPrayerCountdown = countdown);
//   }

//   void _onItemTapped(int index) {
//     if (index == _selectedIndex) return;
//     String routeName = '';
//     switch (index) {
//       case 0:
//         break;
//       case 1:
//         routeName = '/media';
//         break;
//       case 2:
//         routeName = '/prayer';
//         break;
//       case 3:
//         routeName = '/chatbot';
//         break;
//       case 4:
//         routeName = '/subapps';
//         break;
//     }
//     if (routeName.isNotEmpty) {
//       Navigator.pushReplacementNamed(context, routeName);
//     }
//   }

//   final List<Map<String, dynamic>> _appsData = const [
//     {
//       'name': 'Alfurqan',
//       'image': 'assets/images/alfuqan.jpg',
//       'url': 'https://Skylinkict.com/alfurqan'
//     },
//     {
//       'name': 'Kirbgebeya',
//       'image': 'assets/images/kirbgebeya.png',
//       'url': 'https://kirbgebeya.com/'
//     },
//     {
//       'name': 'Almathurat',
//       'image': 'assets/images/almathurat.jpg',
//       'url': 'https://Skylinkict.com/almathurat'
//     },
//     {'name': 'Besirah', 'image': 'assets/images/besira.jpg', 'url': null},
//   ];

//   String _formatTimeAgo(String dateString) {
//     try {
//       final dateTime = DateTime.parse(dateString);
//       final now = DateTime.now();
//       final difference = now.difference(dateTime);
//       if (difference.inDays > 365)
//         return '${(difference.inDays / 365).floor()}y ago';
//       if (difference.inDays > 30)
//         return '${(difference.inDays / 30).floor()}mo ago';
//       if (difference.inDays > 0) return '${difference.inDays}d ago';
//       if (difference.inHours > 0) return '${difference.inHours}h ago';
//       if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
//       return 'Just now';
//     } catch (e) {
//       return '';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     final screenWidth = MediaQuery.of(context).size.width;
//     // ✅ 3. BUILD THE UI WITH THE DYNAMIC HEIGHT
//     // The banner's height is now perfectly calculated from the video's true shape.
//     final bannerHeight = screenWidth / _bannerAspectRatio;

//     return GestureDetector(
//       onHorizontalDragEnd: (details) {
//         if ((details.primaryVelocity ?? 0).abs() > 400.0) {
//           _scaffoldKey.currentState?.openDrawer();
//         }
//       },
//       child: Scaffold(
//         key: _scaffoldKey,
//         drawer: const AppDrawer(),
//         body: Stack(
//           children: [
//             RefreshIndicator(
//               onRefresh: _refreshData,
//               edgeOffset: 0.0,
//               child: CustomScrollView(
//                 slivers: [
//                   SliverAppBar(
//                     // The height is now dynamic.
//                     expandedHeight: bannerHeight,
//                     pinned: false,
//                     floating: true,
//                     snap: true,
//                     backgroundColor: Colors.transparent,
//                     elevation: 0,
//                     automaticallyImplyLeading: false,
//                     flexibleSpace: FlexibleSpaceBar(
//                       background: _buildVideoBanner(context, bannerHeight),
//                     ),
//                   ),
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const SizedBox(height: 24),
//                           _buildPrayerTimesSection(theme, isDarkMode),
//                           const SizedBox(height: 24),
//                           _buildSectionHeader(theme, "Trending on Minber", () {
//                             if (_trendingVideos != null &&
//                                 _trendingVideos!.isNotEmpty) {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => TrendingSeeAllScreen(
//                                     trendingVideos: _trendingVideos!,
//                                     apiBaseUrl: _apiBaseUrl,
//                                   ),
//                                 ),
//                               );
//                             }
//                           }),
//                           const SizedBox(height: 12),
//                         ],
//                       ),
//                     ),
//                   ),
//                   _buildTrendingSection(context, theme, isDarkMode),
//                   SliverToBoxAdapter(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const SizedBox(height: 24),
//                           _buildHalalPremium(theme, isDarkMode),
//                           const SizedBox(height: 24),
//                           _buildSectionHeader(theme, "Explore Our Apps", () {
//                             Navigator.pushNamed(context, '/subapps');
//                           }),
//                           const SizedBox(height: 16),
//                           _buildAppsSection(theme),
//                           const SizedBox(height: 20),
//                           _buildSectionHeader(theme, "Latest News", () {
//                             if (_newsArticles != null &&
//                                 _newsArticles!.isNotEmpty) {
//                               Navigator.pushNamed(context, '/news', arguments: {
//                                 'newsArticles': _newsArticles,
//                                 'apiBaseUrl': _apiBaseUrl
//                               });
//                             }
//                           }),
//                           const SizedBox(height: 12),
//                           _buildNewsSection(theme),
//                           const SizedBox(height: 24),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Positioned(
//               left: -10,
//               top: 0,
//               bottom: 0,
//               child: Center(
//                 child: DrawerIndicator(
//                   onTap: () => _scaffoldKey.currentState?.openDrawer(),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         bottomNavigationBar: _buildBottomNavigationBar(theme),
//       ),
//     );
//   }

//   Widget _buildVideoBanner(BuildContext context, double bannerHeight) {
//     return Container(
//       color: Colors.black,
//       height: bannerHeight,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // ✅ 4. WRAP THE PLAYER IN AN AspectRatio WIDGET
//           // This enforces the container shape and guarantees a perfect fit.
//           if (_bannerPlayerController != null)
//             AspectRatio(
//               aspectRatio: _bannerAspectRatio,
//               child: BetterPlayer(
//                 controller: _bannerPlayerController!,
//               ),
//             ),

//           // Loading Overlay
//           if (_isBannerLoading)
//             Container(
//               color: Colors.black.withOpacity(0.8),
//               child: const Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     CircularProgressIndicator(color: Colors.white),
//                     SizedBox(height: 12),
//                     Text('Loading Stream...',
//                         style: TextStyle(color: Colors.white70)),
//                   ],
//                 ),
//               ),
//             ),

//           // Error Overlay
//           if (_hasBannerError)
//             Container(
//               color: Colors.black.withOpacity(0.8),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.error_outline,
//                       color: Colors.white, size: 40),
//                   const SizedBox(height: 12),
//                   const Text('Stream Error',
//                       style: TextStyle(color: Colors.white)),
//                   const SizedBox(height: 12),
//                   ElevatedButton.icon(
//                     onPressed: _reloadBannerStream,
//                     icon: const Icon(Icons.refresh, size: 16),
//                     label: const Text('Retry'),
//                   ),
//                 ],
//               ),
//             ),

//           // UI Controls (only show when video is playing)
//           if (!_hasBannerError && !_isBannerLoading) ...[
//             Positioned(
//               top: 40,
//               left: 12,
//               child: Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.6),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: const Row(
//                   children: [
//                     Icon(Icons.circle, color: Colors.red, size: 10),
//                     SizedBox(width: 6),
//                     Text("LIVE",
//                         style: TextStyle(color: Colors.white, fontSize: 12)),
//                   ],
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 40,
//               right: 12,
//               child: GestureDetector(
//                 onTap: _toggleMute,
//                 child: Container(
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.6),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     _isMuted ? Icons.volume_off : Icons.volume_up,
//                     color: Colors.white,
//                     size: 20,
//                   ),
//                 ),
//               ),
//             ),
//             Positioned(
//               bottom: 12,
//               right: 12,
//               child: GestureDetector(
//                 onTap: _navigateToLivePage,
//                 child: Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.6),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Text(
//                     "Tap for full screen →",
//                     style: TextStyle(color: Colors.white, fontSize: 12),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildPrayerTimesSection(ThemeData theme, bool isDarkMode) {
//     const prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
//     final timeFormatter = DateFormat("h:mm a");
//     return Container(
//       padding: const EdgeInsets.all(16.0),
//       decoration: BoxDecoration(
//         color: isDarkMode ? AppColors.surfaceDark : const Color(0xFFF7F9FC),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         children: [
//           _isLoadingPrayerTimes
//               ? _buildPrayerTimesHeaderShimmer(theme)
//               : Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Next Prayer: $_nextPrayerName',
//                             style: theme.textTheme.titleMedium?.copyWith(
//                                 fontWeight: FontWeight.bold,
//                                 color: AppColors.primaryBlue)),
//                         Text('in $_nextPrayerCountdown',
//                             style: theme.textTheme.bodyLarge
//                                 ?.copyWith(fontWeight: FontWeight.w600)),
//                       ],
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.arrow_forward_ios,
//                           size: 18, color: AppColors.primaryBlue),
//                       onPressed: () => Navigator.pushNamed(context, '/prayer'),
//                     )
//                   ],
//                 ),
//           const Divider(height: 32),
//           _isLoadingPrayerTimes
//               ? _buildPrayerTimesRowShimmer(theme)
//               : Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: prayerOrder.map((prayerName) {
//                     final isActive = _nextPrayerName.startsWith(prayerName);
//                     final prayerDateTime = _prayerTimes[prayerName];
//                     return Expanded(
//                       child: _buildPrayerTimeColumn(
//                         theme: theme,
//                         prayerName: prayerName,
//                         time: prayerDateTime != null
//                             ? timeFormatter.format(prayerDateTime)
//                             : "--:--",
//                         isActive: isActive,
//                       ),
//                     );
//                   }).toList(),
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPrayerTimeColumn({
//     required ThemeData theme,
//     required String prayerName,
//     required String time,
//     required bool isActive,
//   }) {
//     final parts = time.split(' ');
//     final timeString = parts[0];
//     final periodString = parts.length > 1 ? parts[1] : '';
//     final Color nameAndPrayerTimeColor =
//         isActive ? Colors.white : theme.textTheme.bodyLarge!.color!;
//     final Color periodColor = isActive ? Colors.white70 : theme.hintColor;
//     final FontWeight fontWeight =
//         isActive ? FontWeight.bold : FontWeight.normal;
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 400),
//       curve: Curves.easeInOut,
//       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
//       decoration: BoxDecoration(
//         color: isActive ? AppColors.primaryBlue : Colors.transparent,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Text(prayerName,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                   fontWeight: fontWeight, color: nameAndPrayerTimeColor),
//               textAlign: TextAlign.center),
//           const SizedBox(height: 8),
//           Text(timeString,
//               style: theme.textTheme.titleSmall?.copyWith(
//                   fontWeight: fontWeight, color: nameAndPrayerTimeColor),
//               textAlign: TextAlign.center),
//           if (periodString.isNotEmpty)
//             Text(periodString,
//                 style: theme.textTheme.bodySmall?.copyWith(color: periodColor)),
//         ],
//       ),
//     );
//   }

//   Widget _buildPrayerTimesHeaderShimmer(ThemeData theme) {
//     return Shimmer.fromColors(
//       baseColor: theme.splashColor,
//       highlightColor: theme.cardColor,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                   width: 150,
//                   height: 16,
//                   color: Colors.white,
//                   margin: const EdgeInsets.only(bottom: 8)),
//               Container(width: 100, height: 14, color: Colors.white),
//             ],
//           ),
//           Container(width: 24, height: 24, color: Colors.white),
//         ],
//       ),
//     );
//   }

//   Widget _buildPrayerTimesRowShimmer(ThemeData theme) {
//     return Shimmer.fromColors(
//       baseColor: theme.splashColor,
//       highlightColor: theme.cardColor,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: List.generate(
//             5,
//             (_) => Expanded(
//                   child: Column(
//                     children: [
//                       Container(
//                           width: 40,
//                           height: 12,
//                           color: Colors.white,
//                           margin: const EdgeInsets.only(bottom: 6)),
//                       Container(width: 50, height: 16, color: Colors.white),
//                     ],
//                   ),
//                 )),
//       ),
//     );
//   }

//   SliverToBoxAdapter _buildTrendingSection(
//       BuildContext context, ThemeData theme, bool isDarkMode) {
//     return SliverToBoxAdapter(
//       child: SizedBox(
//         height: MediaQuery.of(context).size.width * 0.45,
//         child: _trendingVideos == null && _trendingError == null
//             ? _buildTrendingShimmer(context)
//             : _trendingError != null
//                 ? _buildTrendingError(theme)
//                 : _trendingVideos!.isEmpty
//                     ? _buildNoTrendingContent(theme)
//                     : ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: _trendingVideos!.length,
//                         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                         itemBuilder: (context, index) {
//                           final video = _trendingVideos![index];
//                           return _buildTrendingItem(
//                               context, theme, video, index, isDarkMode);
//                         },
//                       ),
//       ),
//     );
//   }

//   Widget _buildTrendingItem(BuildContext context, ThemeData theme,
//       dynamic video, int index, bool isDarkMode) {
//     String thumbnailUrl = video['thumbnail'] ?? '';
//     if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('http')) {
//       if (thumbnailUrl.startsWith('/')) {
//         thumbnailUrl = '$_apiBaseUrl$thumbnailUrl';
//       } else {
//         thumbnailUrl = '$_apiBaseUrl/$thumbnailUrl';
//       }
//     }
//     return Container(
//       width: MediaQuery.of(context).size.width * 0.65,
//       margin: const EdgeInsets.only(right: 12),
//       clipBehavior: Clip.antiAlias,
//       decoration: BoxDecoration(
//         color: isDarkMode ? AppColors.surfaceDark : const Color(0xFFF7F9FC),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: GestureDetector(
//         onTap: () {
//           final videoUrl = video['videoUrl'] as String?;
//           if (videoUrl == null || videoUrl.isEmpty) {
//             ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('No video URL available.')));
//             return;
//           }
//           String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
//           if (videoId != null && videoId.isNotEmpty) {
//             final List<Video> videoPlaylist =
//                 _trendingVideos!.map<Video>((item) {
//               final url = item['videoUrl'] as String? ?? '';
//               final id = YoutubePlayer.convertUrlToId(url) ?? '';
//               String thumb = item['thumbnail'] ?? '';
//               if (thumb.isNotEmpty && !thumb.startsWith('http')) {
//                 thumb = '$_apiBaseUrl$thumb';
//               }
//               return Video(
//                 id: id,
//                 videoId: id,
//                 title: item['title'] ?? 'Untitled',
//                 thumbnailUrl: thumb,
//                 publishedAt: DateTime.now(),
//                 privacyStatus: '',
//               );
//             }).toList();
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => VideoPlayerScreen(
//                   videoId: videoId,
//                   initialIndex: index,
//                   videoList: videoPlaylist,
//                   initialVideo: videoPlaylist[index],
//                 ),
//               ),
//             );
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//                 content: Text('Could not play video (Invalid URL).')));
//           }
//         },
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             if (thumbnailUrl.isNotEmpty)
//               Image.network(thumbnailUrl,
//                   fit: BoxFit.cover,
//                   errorBuilder: (context, error, stackTrace) =>
//                       Container(color: theme.splashColor))
//             else
//               Container(color: theme.splashColor),
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Colors.black.withOpacity(0.8),
//                     Colors.black.withOpacity(0.0)
//                   ],
//                   begin: Alignment.bottomCenter,
//                   end: Alignment.center,
//                 ),
//               ),
//             ),
//             Center(
//                 child: Icon(Icons.play_circle_fill,
//                     color: Colors.white.withOpacity(0.8), size: 40)),
//             Positioned(
//               bottom: 8,
//               left: 8,
//               right: 8,
//               child: Text(
//                 video['title']?.toString() ?? 'Untitled',
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                     fontWeight: FontWeight.bold, color: Colors.white),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTrendingShimmer(BuildContext context) {
//     return ListView.builder(
//       scrollDirection: Axis.horizontal,
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       itemCount: 3,
//       itemBuilder: (context, index) => Shimmer.fromColors(
//         baseColor: Colors.grey[300]!,
//         highlightColor: Colors.grey[100]!,
//         child: Container(
//           width: MediaQuery.of(context).size.width * 0.65,
//           margin: const EdgeInsets.only(right: 12),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTrendingError(ThemeData theme) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.error_outline, color: theme.hintColor, size: 40),
//           const SizedBox(height: 8),
//           Text('Failed to load trending',
//               style:
//                   theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
//           const SizedBox(height: 8),
//           ElevatedButton(
//               onPressed: () => _fetchTrendingVideos(forceRefresh: true),
//               child: const Text('Retry')),
//         ],
//       ),
//     );
//   }

//   Widget _buildNoTrendingContent(ThemeData theme) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.trending_up, color: theme.hintColor, size: 40),
//           const SizedBox(height: 8),
//           Text('No trending content',
//               style:
//                   theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
//         ],
//       ),
//     );
//   }

//   Widget _buildHalalPremium(ThemeData theme, bool isDarkMode) {
//     return Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             gradient: const LinearGradient(
//               colors: [AppColors.primaryBlue, AppColors.accentBlue],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             )),
//         child: Row(children: [
//           const Icon(Icons.workspace_premium_outlined,
//               color: Colors.white, size: 40),
//           const SizedBox(width: 16),
//           Expanded(
//               child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                 Text("Halal Premium",
//                     style: theme.textTheme.titleMedium?.copyWith(
//                         fontWeight: FontWeight.bold, color: Colors.white)),
//                 const SizedBox(height: 4),
//                 Text("Enjoy ad-free streaming and exclusive content.",
//                     style: theme.textTheme.bodyMedium
//                         ?.copyWith(color: Colors.white70))
//               ])),
//           const SizedBox(width: 12),
//           ElevatedButton(
//               onPressed: () => Navigator.pushNamed(context, "/subscription"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.white,
//                 foregroundColor: AppColors.primaryBlue,
//               ),
//               child: const Text("Upgrade"))
//         ]));
//   }

//   Widget _buildAppsSection(ThemeData theme) {
//     return SizedBox(
//       height: 125,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         itemCount: _appsData.length,
//         separatorBuilder: (context, index) => const SizedBox(width: 20),
//         itemBuilder: (context, index) {
//           final app = _appsData[index];
//           return _buildAppCard(theme, app);
//         },
//       ),
//     );
//   }

//   Widget _buildAppCard(ThemeData theme, Map<String, dynamic> app) {
//     return SizedBox(
//       width: 80,
//       child: GestureDetector(
//         onTap: () {
//           final url = app['url'] as String?;
//           if (url != null) {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (context) =>
//                         EmbeddedWebScreen(url: url, appName: app['name'])));
//           } else {
//             Navigator.pushNamed(context, '/coming-soon',
//                 arguments: app['name']);
//           }
//         },
//         child: Column(
//           children: [
//             CircleAvatar(radius: 35, backgroundImage: AssetImage(app['image'])),
//             const SizedBox(height: 8),
//             Text(app['name'],
//                 textAlign: TextAlign.center,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: theme.textTheme.bodyMedium
//                     ?.copyWith(fontWeight: FontWeight.w500)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionHeader(
//       ThemeData theme, String title, VoidCallback onViewAll) {
//     return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//       Text(title,
//           style: theme.textTheme.titleLarge
//               ?.copyWith(fontWeight: FontWeight.bold)),
//       TextButton(
//           onPressed: onViewAll,
//           child: Text("View All",
//               style: theme.textTheme.bodyMedium?.copyWith(
//                   color: AppColors.primaryBlue, fontWeight: FontWeight.bold)))
//     ]);
//   }

//   Widget _buildNewsSection(ThemeData theme) {
//     if (_newsArticles == null && _newsError == null) {
//       return _buildNewsShimmer(theme);
//     }
//     if (_newsError != null) {
//       return _buildNewsError(theme);
//     }
//     if (_newsArticles!.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.newspaper, color: theme.hintColor, size: 40),
//             const SizedBox(height: 8),
//             Text('No news available right now.',
//                 style: theme.textTheme.bodyMedium
//                     ?.copyWith(color: theme.hintColor)),
//           ],
//         ),
//       );
//     }
//     return ListView.separated(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: min(3, _newsArticles!.length),
//       separatorBuilder: (context, index) => const SizedBox(height: 12),
//       itemBuilder: (context, index) {
//         final item = _newsArticles![index];
//         final headline = item['headline'] ?? 'No Title';
//         final newsUrl = item['newsUrl'] as String?;
//         String thumbnailUrl = item['thumbnail'] ?? '';
//         if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('http')) {
//           if (thumbnailUrl.startsWith('/')) {
//             thumbnailUrl = '$_apiBaseUrl$thumbnailUrl';
//           } else {
//             thumbnailUrl = '$_apiBaseUrl/$thumbnailUrl';
//           }
//         }
//         final isDarkMode = theme.brightness == Brightness.dark;
//         final cardBackgroundColor =
//             isDarkMode ? AppColors.surfaceDark : const Color(0xFFF7F9FC);
//         final newsCard = Container(
//           decoration: BoxDecoration(
//             color: cardBackgroundColor,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: InkWell(
//             borderRadius: BorderRadius.circular(12),
//             onTap: () {
//               if (newsUrl != null && newsUrl.isNotEmpty) {
//                 Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => EmbeddedWebScreen(
//                             url: newsUrl, appName: headline)));
//               }
//             },
//             child: Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(headline,
//                             style: theme.textTheme.bodyMedium
//                                 ?.copyWith(fontWeight: FontWeight.bold),
//                             maxLines: 3,
//                             overflow: TextOverflow.ellipsis),
//                         const SizedBox(height: 8),
//                         Text(_formatTimeAgo(item["createdAt"] ?? ''),
//                             style: theme.textTheme.bodySmall
//                                 ?.copyWith(color: theme.hintColor)),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: thumbnailUrl.isNotEmpty
//                         ? Image.network(thumbnailUrl,
//                             width: 80,
//                             height: 80,
//                             fit: BoxFit.cover,
//                             errorBuilder: (c, e, s) => Container(
//                                 width: 80,
//                                 height: 80,
//                                 color: theme.splashColor,
//                                 child:
//                                     const Icon(Icons.broken_image, size: 30)))
//                         : Container(
//                             width: 80,
//                             height: 80,
//                             color: theme.splashColor,
//                             child: const Icon(Icons.image, size: 30)),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//         return AnimatedListItem(index: index, child: newsCard);
//       },
//     );
//   }

//   Widget _buildNewsShimmer(ThemeData theme) {
//     return Shimmer.fromColors(
//       baseColor: theme.splashColor,
//       highlightColor: theme.cardColor,
//       child: ListView.separated(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: 3,
//         separatorBuilder: (context, index) => const SizedBox(height: 12),
//         itemBuilder: (context, index) {
//           return Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: theme.dividerColor.withOpacity(0.8)),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                           width: double.infinity,
//                           height: 16,
//                           color: Colors.white),
//                       const SizedBox(height: 8),
//                       Container(width: 200, height: 16, color: Colors.white),
//                       const SizedBox(height: 8),
//                       Container(width: 80, height: 12, color: Colors.white),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Container(width: 80, height: 80, color: Colors.white),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildNewsError(ThemeData theme) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.error_outline, color: theme.hintColor, size: 40),
//           const SizedBox(height: 8),
//           Text('Failed to load news',
//               style:
//                   theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
//           const SizedBox(height: 8),
//           ElevatedButton(
//               onPressed: () => _fetchNewsArticles(forceRefresh: true),
//               child: const Text('Retry')),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomNavigationBar(ThemeData theme) {
//     return Container(
//       decoration: BoxDecoration(
//         color: theme.cardColor,
//         border: Border(top: BorderSide(color: theme.dividerColor, width: 1.0)),
//       ),
//       child: BottomNavigationBar(
//           currentIndex: _selectedIndex,
//           onTap: _onItemTapped,
//           selectedItemColor: theme.colorScheme.primary,
//           unselectedItemColor: theme.unselectedWidgetColor,
//           type: BottomNavigationBarType.fixed,
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           items: const [
//             BottomNavigationBarItem(
//                 icon: Icon(Icons.home_outlined),
//                 activeIcon: Icon(Icons.home),
//                 label: "Home"),
//             BottomNavigationBarItem(
//                 icon: Icon(Icons.tv_outlined),
//                 activeIcon: Icon(Icons.tv),
//                 label: "Media"),
//             BottomNavigationBarItem(
//                 icon: Icon(Icons.mosque_outlined),
//                 activeIcon: Icon(Icons.mosque),
//                 label: "Prayer"),
//             BottomNavigationBarItem(
//                 icon: Icon(Icons.chat_bubble_outline),
//                 activeIcon: Icon(Icons.chat_bubble),
//                 label: "Chat Bot"),
//             BottomNavigationBarItem(
//                 icon: Icon(Icons.apps_outlined),
//                 activeIcon: Icon(Icons.apps),
//                 label: "Sub Apps"),
//           ]),
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:minber/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../core/app_colors.dart';
import '../models/video_model.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/app_drawer.dart';
import '../widgets/drawer_indicator.dart';
import '../widgets/embedded_web_screen.dart';
import 'trending_see_all_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  Timer? _timer;
  Timer? _autoRefreshTimer;
  BetterPlayerController? _bannerPlayerController;
  bool _isBannerLoading = true;
  bool _hasBannerError = false;
  bool _isMuted = true;
  final String streamUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

  // Default fallback aspect ratio (16:9)
  static const double _defaultAspectRatio = 16 / 9;
  late double _bannerAspectRatio;

  String _nextPrayerName = "";
  String _nextPrayerCountdown = "--:--:--";
  Map<String, DateTime> _prayerTimes = {};
  bool _isLoadingPrayerTimes = true;
  List<dynamic>? _trendingVideos;
  List<dynamic>? _newsArticles;
  String? _trendingError;
  String? _newsError;
  static const _trendingCacheKey = 'home_trending_cache';
  static const _newsCacheKey = 'home_news_cache';
  static const _trendingTimestampKey = 'home_trending_timestamp';
  static const _newsTimestampKey = 'home_news_timestamp, timestamp';
  static const _cacheValidityMinutes = 5;
  final String _trendingApiUrl = 'http://msa.merkuz.com:3636/trending';
  final String _newsApiUrl = 'http://msa.merkuz.com:3636/news';
  final String _apiBaseUrl = 'http://msa.merkuz.com:3636';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bannerAspectRatio = _defaultAspectRatio; // Start with safe default
    _initializeBannerPlayer();
    _initializePrayerTimes();
    _loadDataWithCache();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_prayerTimes.isNotEmpty) _updateCountdown();
    });
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _refreshData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _bannerPlayerController?.play();
      _refreshData();
    } else if (state == AppLifecycleState.paused) {
      _bannerPlayerController?.pause();
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _bannerPlayerController?.dispose();
    _bannerPlayerController = null;
    super.dispose();
  }

  @override
  void didPushNext() {
    _bannerPlayerController?.pause();
  }

  @override
  void didPopNext() {
    _bannerPlayerController?.play();
  }

  Future<void> _initializeBannerPlayer() async {
    if (mounted) {
      setState(() {
        _isBannerLoading = true;
        _hasBannerError = false;
        _bannerAspectRatio = _defaultAspectRatio; // Reset to default
      });
    }

    _bannerPlayerController?.dispose();

    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      streamUrl,
      liveStream: true,
      notificationConfiguration:
          const BetterPlayerNotificationConfiguration(showNotification: false),
    );

    _bannerPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: true,
        fit: BoxFit.fill, // Will be perfect once ratio is set
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
        ),
        handleLifecycle: true,
        aspectRatio: _bannerAspectRatio,
      ),
      betterPlayerDataSource: dataSource,
    );

    _bannerPlayerController!.setVolume(0.0);
    _bannerPlayerController!.addEventsListener(_onPlayerEvent);
  }

  void _onPlayerEvent(BetterPlayerEvent event) async {
    if (!mounted) return;

    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.initialized:
      case BetterPlayerEventType.bufferingEnd:
        final controller = _bannerPlayerController?.videoPlayerController;
        if (controller != null && controller.value.initialized) {
          final double? videoAspectRatio = controller.value.aspectRatio;
          if (videoAspectRatio != null &&
              videoAspectRatio > 0.5 &&
              videoAspectRatio < 3.0) {
            // Only update if significantly different
            if ((videoAspectRatio - _bannerAspectRatio).abs() > 0.01) {
              setState(() {
                _bannerAspectRatio = videoAspectRatio;
                _bannerPlayerController
                    ?.setOverriddenAspectRatio(videoAspectRatio);
              });
            }
          }
        }
        setState(() {
          _isBannerLoading = false;
          _hasBannerError = false;
        });
        break;

      case BetterPlayerEventType.exception:
        setState(() {
          _isBannerLoading = false;
          _hasBannerError = true;
        });
        break;

      case BetterPlayerEventType.bufferingStart:
        setState(() => _isBannerLoading = true);
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth / _bannerAspectRatio;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0).abs() > 400.0) {
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refreshData,
              edgeOffset: 0.0,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: bannerHeight,
                    pinned: false,
                    floating: true,
                    snap: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      background: _buildVideoBanner(context, bannerHeight),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildPrayerTimesSection(theme, isDarkMode),
                          const SizedBox(height: 24),
                          _buildSectionHeader(theme, "Trending on Minber", () {
                            if (_trendingVideos != null &&
                                _trendingVideos!.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TrendingSeeAllScreen(
                                    trendingVideos: _trendingVideos!,
                                    apiBaseUrl: _apiBaseUrl,
                                  ),
                                ),
                              );
                            }
                          }),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  _buildTrendingSection(context, theme, isDarkMode),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildHalalPremium(theme, isDarkMode),
                          const SizedBox(height: 24),
                          _buildSectionHeader(theme, "Explore Our Apps", () {
                            Navigator.pushNamed(context, '/subapps');
                          }),
                          const SizedBox(height: 16),
                          _buildAppsSection(theme),
                          const SizedBox(height: 20),
                          _buildSectionHeader(theme, "Latest News", () {
                            if (_newsArticles != null &&
                                _newsArticles!.isNotEmpty) {
                              Navigator.pushNamed(context, '/news', arguments: {
                                'newsArticles': _newsArticles,
                                'apiBaseUrl': _apiBaseUrl
                              });
                            }
                          }),
                          const SizedBox(height: 12),
                          _buildNewsSection(theme),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: -10,
              top: 0,
              bottom: 0,
              child: Center(
                child: DrawerIndicator(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(theme),
      ),
    );
  }

  Widget _buildVideoBanner(BuildContext context, double bannerHeight) {
    return Container(
      color: Colors.black,
      height: bannerHeight,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_bannerPlayerController != null)
            AspectRatio(
              aspectRatio: _bannerAspectRatio,
              child: BetterPlayer(
                controller: _bannerPlayerController!,
              ),
            ),

          // Loading Overlay
          if (_isBannerLoading)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text('Loading Stream...',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),

          // Error Overlay
          if (_hasBannerError)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  const Text('Stream Error',
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _reloadBannerStream,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // UI Controls (only show when playing)
          if (!_hasBannerError && !_isBannerLoading) ...[
            Positioned(
              top: 40,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.red, size: 10),
                    SizedBox(width: 6),
                    Text("LIVE",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 12,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: GestureDetector(
                onTap: _navigateToLivePage,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Tap for full screen",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _reloadBannerStream() {
    _initializeBannerPlayer();
  }

  void _toggleMute() {
    if (mounted) {
      setState(() {
        _isMuted = !_isMuted;
      });
      _bannerPlayerController?.setVolume(_isMuted ? 0.0 : 1.0);
    }
  }

  void _navigateToLivePage() async {
    await _bannerPlayerController?.pause();
    Navigator.pushNamed(context, '/live').then((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _bannerPlayerController?.play();
        });
      }
    });
  }

  // === REST OF YOUR CODE (UNCHANGED BELOW) ===
  // ... (All other methods: _loadDataWithCache, _refreshData, prayer times, etc.) ...

  Future<void> _loadDataWithCache() async {
    final prefs = await SharedPreferences.getInstance();
    final lastTrendingTime = prefs.getInt(_trendingTimestampKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final shouldUseTrendingCache =
        (now - lastTrendingTime) < (_cacheValidityMinutes * 60 * 1000);
    if (shouldUseTrendingCache && mounted) {
      final cachedTrending = prefs.getString(_trendingCacheKey);
      if (cachedTrending != null) {
        setState(() => _trendingVideos = json.decode(cachedTrending));
      }
    } else {
      await prefs.remove(_trendingCacheKey);
    }
    final lastNewsTime = prefs.getInt(_newsTimestampKey) ?? 0;
    final shouldUseNewsCache =
        (now - lastNewsTime) < (_cacheValidityMinutes * 60 * 1000);
    if (shouldUseNewsCache && mounted) {
      final cachedNews = prefs.getString(_newsCacheKey);
      if (cachedNews != null) {
        setState(() => _newsArticles = json.decode(cachedNews));
      }
    } else {
      await prefs.remove(_newsCacheKey);
    }
    await _fetchTrendingVideos();
    await _fetchNewsArticles();
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_trendingCacheKey);
    await prefs.remove(_newsCacheKey);
    await prefs.remove(_trendingTimestampKey);
    await prefs.remove(_newsTimestampKey);
    if (mounted) {
      setState(() {
        _trendingVideos = null;
        _newsArticles = null;
        _trendingError = null;
        _newsError = null;
      });
    }
    await Future.wait([
      _getLocationAndPrayerTimes(),
      _fetchTrendingVideos(forceRefresh: true),
      _fetchNewsArticles(forceRefresh: true),
    ]);
  }

  Future<void> _fetchTrendingVideos({bool forceRefresh = false}) async {
    try {
      final response = await http.get(Uri.parse(_trendingApiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_trendingCacheKey, response.body);
        await prefs.setInt(
            _trendingTimestampKey, DateTime.now().millisecondsSinceEpoch);
        if (mounted) {
          setState(() {
            _trendingVideos = data;
            _trendingError = null;
          });
        }
      } else {
        throw Exception('Failed to load trending videos');
      }
    } catch (e) {
      print("Trending fetch error: $e");
      if (mounted && (_trendingVideos == null || _trendingVideos!.isEmpty)) {
        setState(() => _trendingError = e.toString());
      }
    }
  }

  Future<void> _fetchNewsArticles({bool forceRefresh = false}) async {
    try {
      final response = await http.get(Uri.parse(_newsApiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_newsCacheKey, response.body);
        await prefs.setInt(
            _newsTimestampKey, DateTime.now().millisecondsSinceEpoch);
        if (mounted) {
          setState(() {
            _newsArticles = data;
            _newsError = null;
          });
        }
      } else {
        throw Exception('Failed to load news articles');
      }
    } catch (e) {
      print("News fetch error: $e");
      if (mounted && (_newsArticles == null || _newsArticles!.isEmpty)) {
        setState(() => _newsError = e.toString());
      }
    }
  }

  Future<void> _initializePrayerTimes() async {
    final bool loadedFromCache = await _loadCachedPrayerTimes();
    if (loadedFromCache) {
      _updateNextPrayerAndCountdown();
      if (mounted) setState(() => _isLoadingPrayerTimes = false);
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
      if (mounted) {
        setState(() {
          _prayerTimes = {
            'Fajr': DateTime.parse(decodedTimes['Fajr']),
            'Dhuhr': DateTime.parse(decodedTimes['Dhuhr']),
            'Asr': DateTime.parse(decodedTimes['Asr']),
            'Maghrib': DateTime.parse(decodedTimes['Maghrib']),
            'Isha': DateTime.parse(decodedTimes['Isha']),
          };
        });
      }
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
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
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
        ..madhab = Madhab.shafi,
    );
    if (mounted) {
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
  }

  void _updateNextPrayerAndCountdown() {
    final now = DateTime.now();
    String nextPrayer = "Fajr (Tomorrow)";
    DateTime? nextPrayerDateTime;
    final prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    for (var prayerName in prayerOrder) {
      final prayerTime = _prayerTimes[prayerName];
      if (prayerTime != null && now.isBefore(prayerTime)) {
        nextPrayer = prayerName;
        nextPrayerDateTime = prayerTime;
        break;
      }
    }
    if (nextPrayerDateTime == null) {
      nextPrayerDateTime = _prayerTimes['Fajr']?.add(const Duration(days: 1));
    }
    if (mounted) setState(() => _nextPrayerName = nextPrayer);
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

  final List<Map<String, dynamic>> _appsData = const [
    {
      'name': 'Alfurqan',
      'image': 'assets/images/alfuqan.jpg',
      'url': 'https://Skylinkict.com/alfurqan'
    },
    {
      'name': 'Kirbgebeya',
      'image': 'assets/images/kirbgebeya.png',
      'url': 'https://kirbgebeya.com/'
    },
    {
      'name': 'Almathurat',
      'image': 'assets/images/almathurat.jpg',
      'url': 'https://Skylinkict.com/almathurat'
    },
    {'name': 'Besirah', 'image': 'assets/images/besira.jpg', 'url': null},
  ];

  String _formatTimeAgo(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      if (difference.inDays > 365)
        return '${(difference.inDays / 365).floor()}y ago';
      if (difference.inDays > 30)
        return '${(difference.inDays / 30).floor()}mo ago';
      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return '';
    }
  }

  Widget _buildPrayerTimesSection(ThemeData theme, bool isDarkMode) {
    const prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final timeFormatter = DateFormat("h:mm a");
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _isLoadingPrayerTimes
              ? _buildPrayerTimesHeaderShimmer(theme)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Next Prayer: $_nextPrayerName',
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue)),
                        Text('in $_nextPrayerCountdown',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios,
                          size: 18, color: AppColors.primaryBlue),
                      onPressed: () => Navigator.pushNamed(context, '/prayer'),
                    )
                  ],
                ),
          const Divider(height: 32),
          _isLoadingPrayerTimes
              ? _buildPrayerTimesRowShimmer(theme)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: prayerOrder.map((prayerName) {
                    final isActive = _nextPrayerName.startsWith(prayerName);
                    final prayerDateTime = _prayerTimes[prayerName];
                    return Expanded(
                      child: _buildPrayerTimeColumn(
                        theme: theme,
                        prayerName: prayerName,
                        time: prayerDateTime != null
                            ? timeFormatter.format(prayerDateTime)
                            : "--:--",
                        isActive: isActive,
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeColumn({
    required ThemeData theme,
    required String prayerName,
    required String time,
    required bool isActive,
  }) {
    final parts = time.split(' ');
    final timeString = parts[0];
    final periodString = parts.length > 1 ? parts[1] : '';
    final Color nameAndPrayerTimeColor =
        isActive ? Colors.white : theme.textTheme.bodyLarge!.color!;
    final Color periodColor = isActive ? Colors.white70 : theme.hintColor;
    final FontWeight fontWeight =
        isActive ? FontWeight.bold : FontWeight.normal;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(prayerName,
              style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: fontWeight, color: nameAndPrayerTimeColor),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(timeString,
              style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: fontWeight, color: nameAndPrayerTimeColor),
              textAlign: TextAlign.center),
          if (periodString.isNotEmpty)
            Text(periodString,
                style: theme.textTheme.bodySmall?.copyWith(color: periodColor)),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesHeaderShimmer(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.splashColor,
      highlightColor: theme.cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 150,
                  height: 16,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 8)),
              Container(width: 100, height: 14, color: Colors.white),
            ],
          ),
          Container(width: 24, height: 24, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesRowShimmer(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.splashColor,
      highlightColor: theme.cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
            5,
            (_) => Expanded(
                  child: Column(
                    children: [
                      Container(
                          width: 40,
                          height: 12,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 6)),
                      Container(width: 50, height: 16, color: Colors.white),
                    ],
                  ),
                )),
      ),
    );
  }

  SliverToBoxAdapter _buildTrendingSection(
      BuildContext context, ThemeData theme, bool isDarkMode) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: MediaQuery.of(context).size.width * 0.45,
        child: _trendingVideos == null && _trendingError == null
            ? _buildTrendingShimmer(context)
            : _trendingError != null
                ? _buildTrendingError(theme)
                : _trendingVideos!.isEmpty
                    ? _buildNoTrendingContent(theme)
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _trendingVideos!.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemBuilder: (context, index) {
                          final video = _trendingVideos![index];
                          return _buildTrendingItem(
                              context, theme, video, index, isDarkMode);
                        },
                      ),
      ),
    );
  }

  Widget _buildTrendingItem(BuildContext context, ThemeData theme,
      dynamic video, int index, bool isDarkMode) {
    String thumbnailUrl = video['thumbnail'] ?? '';
    if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('http')) {
      if (thumbnailUrl.startsWith('/')) {
        thumbnailUrl = '$_apiBaseUrl$thumbnailUrl';
      } else {
        thumbnailUrl = '$_apiBaseUrl/$thumbnailUrl';
      }
    }
    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      margin: const EdgeInsets.only(right: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        onTap: () {
          final videoUrl = video['videoUrl'] as String?;
          if (videoUrl == null || videoUrl.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No video URL available.')));
            return;
          }
          String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
          if (videoId != null && videoId.isNotEmpty) {
            final List<Video> videoPlaylist =
                _trendingVideos!.map<Video>((item) {
              final url = item['videoUrl'] as String? ?? '';
              final id = YoutubePlayer.convertUrlToId(url) ?? '';
              String thumb = item['thumbnail'] ?? '';
              if (thumb.isNotEmpty && !thumb.startsWith('http')) {
                thumb = '$_apiBaseUrl$thumb';
              }
              return Video(
                id: id,
                videoId: id,
                title: item['title'] ?? 'Untitled',
                thumbnailUrl: thumb,
                publishedAt: DateTime.now(),
                privacyStatus: '',
              );
            }).toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoPlayerScreen(
                  videoId: videoId,
                  initialIndex: index,
                  videoList: videoPlaylist,
                  initialVideo: videoPlaylist[index],
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Could not play video (Invalid URL).')));
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl.isNotEmpty)
              Image.network(thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: theme.splashColor))
            else
              Container(color: theme.splashColor),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.0)
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                ),
              ),
            ),
            Center(
                child: Icon(Icons.play_circle_fill,
                    color: Colors.white.withOpacity(0.8), size: 40)),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                video['title']?.toString() ?? 'Untitled',
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingShimmer(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.65,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: theme.hintColor, size: 40),
          const SizedBox(height: 8),
          Text('Failed to load trending',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: () => _fetchTrendingVideos(forceRefresh: true),
              child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildNoTrendingContent(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, color: theme.hintColor, size: 40),
          const SizedBox(height: 8),
          Text('No trending content',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }

  Widget _buildHalalPremium(ThemeData theme, bool isDarkMode) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.accentBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )),
        child: Row(children: [
          const Icon(Icons.workspace_premium_outlined,
              color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text("Halal Premium",
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text("Enjoy ad-free streaming and exclusive content.",
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white70))
              ])),
          const SizedBox(width: 12),
          ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, "/subscription"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryBlue,
              ),
              child: const Text("Upgrade"))
        ]));
  }

  Widget _buildAppsSection(ThemeData theme) {
    return SizedBox(
      height: 125,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _appsData.length,
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final app = _appsData[index];
          return _buildAppCard(theme, app);
        },
      ),
    );
  }

  Widget _buildAppCard(ThemeData theme, Map<String, dynamic> app) {
    return SizedBox(
      width: 80,
      child: GestureDetector(
        onTap: () {
          final url = app['url'] as String?;
          if (url != null) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        EmbeddedWebScreen(url: url, appName: app['name'])));
          } else {
            Navigator.pushNamed(context, '/coming-soon',
                arguments: app['name']);
          }
        },
        child: Column(
          children: [
            CircleAvatar(radius: 35, backgroundImage: AssetImage(app['image'])),
            const SizedBox(height: 8),
            Text(app['name'],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      ThemeData theme, String title, VoidCallback onViewAll) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
      TextButton(
          onPressed: onViewAll,
          child: Text("View All",
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryBlue, fontWeight: FontWeight.bold)))
    ]);
  }

  Widget _buildNewsSection(ThemeData theme) {
    if (_newsArticles == null && _newsError == null) {
      return _buildNewsShimmer(theme);
    }
    if (_newsError != null) {
      return _buildNewsError(theme);
    }
    if (_newsArticles!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.newspaper, color: theme.hintColor, size: 40),
            const SizedBox(height: 8),
            Text('No news available right now.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor)),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: min(3, _newsArticles!.length),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _newsArticles![index];
        final headline = item['headline'] ?? 'No Title';
        final newsUrl = item['newsUrl'] as String?;
        String thumbnailUrl = item['thumbnail'] ?? '';
        if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('http')) {
          if (thumbnailUrl.startsWith('/')) {
            thumbnailUrl = '$_apiBaseUrl$thumbnailUrl';
          } else {
            thumbnailUrl = '$_apiBaseUrl/$thumbnailUrl';
          }
        }
        final isDarkMode = theme.brightness == Brightness.dark;
        final cardBackgroundColor =
            isDarkMode ? AppColors.surfaceDark : const Color(0xFFF7F9FC);
        final newsCard = Container(
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (newsUrl != null && newsUrl.isNotEmpty) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EmbeddedWebScreen(
                            url: newsUrl, appName: headline)));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(headline,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text(_formatTimeAgo(item["createdAt"] ?? ''),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: thumbnailUrl.isNotEmpty
                        ? Image.network(thumbnailUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                                width: 80,
                                height: 80,
                                color: theme.splashColor,
                                child:
                                    const Icon(Icons.broken_image, size: 30)))
                        : Container(
                            width: 80,
                            height: 80,
                            color: theme.splashColor,
                            child: const Icon(Icons.image, size: 30)),
                  ),
                ],
              ),
            ),
          ),
        );
        return AnimatedListItem(index: index, child: newsCard);
      },
    );
  }

  Widget _buildNewsShimmer(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.splashColor,
      highlightColor: theme.cardColor,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withOpacity(0.8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 200, height: 16, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 80, height: 12, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 80, height: 80, color: Colors.white),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: theme.hintColor, size: 40),
          const SizedBox(height: 8),
          Text('Failed to load news',
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: () => _fetchNewsArticles(forceRefresh: true),
              child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1.0)),
      ),
      child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.unselectedWidgetColor,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
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
                label: "Sub Apps"),
          ]),
    );
  }
}
