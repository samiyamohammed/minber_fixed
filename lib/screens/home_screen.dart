// // lib/screens/home_screen.dart (Updated with Trending Functionality)
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // <-- REQUIRED for Video Player
// import 'package:intl/intl.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:adhan_dart/adhan_dart.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:webview_flutter_android/webview_flutter_android.dart';
// import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
// import 'package:http/http.dart' as http;
// import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // <-- REQUIRED for Video Player
// import '../widgets/app_drawer.dart';
// import './coming_soon_page.dart';

// // (The EmbeddedWebScreen widget remains the same as before)
// class EmbeddedWebScreen extends StatefulWidget {
//   final String url;
//   final String appName;

//   const EmbeddedWebScreen(
//       {super.key, required this.url, required this.appName});

//   @override
//   State<EmbeddedWebScreen> createState() => _EmbeddedWebScreenState();
// }

// class _EmbeddedWebScreenState extends State<EmbeddedWebScreen> {
//   late final WebViewController _controller;
//   double _loadingProgress = 0;

//   @override
//   void initState() {
//     super.initState();
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onProgress: (int progress) {
//             setState(() {
//               _loadingProgress = progress / 100.0;
//             });
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse(widget.url));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.appName),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(4.0),
//           child: _loadingProgress > 0 && _loadingProgress < 1
//               ? LinearProgressIndicator(value: _loadingProgress)
//               : const SizedBox.shrink(),
//         ),
//       ),
//       body: WebViewWidget(controller: _controller),
//     );
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;
//   Timer? _timer;

//   // Updated: WebView for banner stream
//   WebViewController? _bannerWebViewController;
//   bool _isBannerLoading = true;
//   bool _hasBannerError = false;
//   bool _isMuted = true;
//   final String streamUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

//   String _nextPrayerName = "";
//   String _nextPrayerCountdown = "--:--:--";
//   Map<String, DateTime> _prayerTimes = {};
//   bool _isLoadingPrayerTimes = true;

//   // New: Trending API integration
//   List<dynamic> _trendingVideos = [];
//   bool _isLoadingTrending = true;
//   bool _hasTrendingError = false;
//   // CORRECTED URL
//   final String _trendingApiUrl = 'http://msa.merkuz.com:3636/trending';

//   // --- CORE LOGIC (UNCHANGED) ---

//   @override
//   void initState() {
//     super.initState();
//     _initializeBannerWebView();
//     _initializePrayerTimes();
//     _fetchTrendingVideos(); // New: Fetch trending videos
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (_prayerTimes.isNotEmpty) _updateCountdown();
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _bannerWebViewController = null;
//     super.dispose();
//   }

//   // New: Fetch trending videos from API
//   Future<void> _fetchTrendingVideos() async {
//     try {
//       final response = await http.get(
//         Uri.parse(_trendingApiUrl),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         // Parse the response - it appears to be a JSON array
//         final List<dynamic> responseData = json.decode(response.body);

//         setState(() {
//           _trendingVideos = responseData;
//           _isLoadingTrending = false;
//           _hasTrendingError = false;
//         });
//       } else {
//         throw Exception(
//             'Failed to load trending videos: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching trending videos: $e');
//       setState(() {
//         _isLoadingTrending = false;
//         _hasTrendingError = true;
//       });
//     }
//   }

//   // Updated: Refresh data to include trending videos
//   Future<void> _refreshData() async {
//     await _getLocationAndPrayerTimes();
//     await _fetchTrendingVideos(); // Refresh trending videos too
//   }

//   // (The rest of your core logic remains completely unchanged)
//   // ... from _initializeBannerWebView down to _onItemTapped
//   Future<void> _initializeBannerWebView() async {
//     try {
//       final htmlContent = _createBannerHtml();

//       final PlatformWebViewControllerCreationParams params;

//       if (WebViewPlatform.instance is WebKitWebViewPlatform) {
//         params = WebKitWebViewControllerCreationParams(
//           allowsInlineMediaPlayback: true,
//           mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
//         );
//       } else {
//         params = const PlatformWebViewControllerCreationParams();
//       }

//       _bannerWebViewController =
//           WebViewController.fromPlatformCreationParams(params)
//             ..setJavaScriptMode(JavaScriptMode.unrestricted)
//             ..setBackgroundColor(Colors.black)
//             ..enableZoom(false)
//             ..setNavigationDelegate(
//               NavigationDelegate(
//                 onProgress: (int progress) {
//                   if (progress > 80) {
//                     setState(() {
//                       _isBannerLoading = false;
//                     });
//                   }
//                 },
//                 onPageFinished: (String url) {
//                   setState(() {
//                     _isBannerLoading = false;
//                   });
//                 },
//                 onWebResourceError: (WebResourceError error) {
//                   setState(() {
//                     _hasBannerError = true;
//                     _isBannerLoading = false;
//                   });
//                 },
//               ),
//             );

//       if (_bannerWebViewController!.platform is AndroidWebViewController) {
//         final AndroidWebViewController androidController =
//             _bannerWebViewController!.platform as AndroidWebViewController;
//         androidController.setMediaPlaybackRequiresUserGesture(false);
//       }

//       _bannerWebViewController!.loadHtmlString(htmlContent);
//     } catch (e) {
//       setState(() {
//         _hasBannerError = true;
//         _isBannerLoading = false;
//       });
//     }
//   }

//   String _createBannerHtml() {
//     return '''
// <!DOCTYPE html>
// <html lang="en">
// <head>
//     <meta charset="UTF-8" />
//     <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
//     <title>Live Stream</title>
//     <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
//     <style>
//         * {
//             margin: 0;
//             padding: 0;
//             box-sizing: border-box;
//         }
//         body {
//             margin: 0;
//             background: #000000;
//             overflow: hidden;
//             width: 100vw;
//             height: 100vh;
//             display: flex;
//             justify-content: center;
//             align-items: center;
//             font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
//         }
//         #videoContainer {
//             width: 100%;
//             height: 100%;
//             position: relative;
//             background: #000;
//         }
//         #video {
//             width: 100%;
//             height: 100%;
//             object-fit: cover;
//             background: #000;
//         }
//         #loading {
//             position: absolute;
//             top: 50%;
//             left: 50%;
//             transform: translate(-50%, -50%);
//             color: white;
//             font-size: 14px;
//             text-align: center;
//             z-index: 10;
//         }
//         .spinner {
//             border: 2px solid rgba(255, 255, 255, 0.3);
//             border-radius: 50%;
//             border-top: 2px solid #ffffff;
//             width: 30px;
//             height: 30px;
//             animation: spin 1s linear infinite;
//             margin: 0 auto 10px;
//         }
//         @keyframes spin {
//             0% { transform: rotate(0deg); }
//             100% { transform: rotate(360deg); }
//         }
//         #error {
//             position: absolute;
//             top: 50%;
//             left: 50%;
//             transform: translate(-50%, -50%);
//             color: white;
//             text-align: center;
//             background: rgba(255, 0, 0, 0.1);
//             padding: 15px;
//             border-radius: 8px;
//             border: 1px solid rgba(255, 255, 255, 0.2);
//             font-size: 12px;
//         }
//         #status {
//             position: absolute;
//             top: 10px;
//             left: 10px;
//             background: rgba(0, 0, 0, 0.7);
//             color: white;
//             padding: 6px 12px;
//             borderRadius: 16px;
//             font-size: 12px;
//             z-index: 5;
//             backdrop-filter: blur(10px);
//         }
//     </style>
// </head>
// <body>
//     <div id="videoContainer">
//         <div id="loading">
//             <div class="spinner"></div>
//             Loading stream...
//         </div>
//         <video id="video" muted autoplay playsinline></video>
//         <div id="status">🔴 LIVE</div>
//     </div>

//     <script>
//         const video = document.getElementById("video");
//         const videoContainer = document.getElementById("videoContainer");
//         const loading = document.getElementById("loading");
//         const status = document.getElementById("status");
//         const hlsUrl = "$streamUrl";

//         let hls;
//         let retryCount = 0;
//         const maxRetries = 3;

//         function initializePlayer() {
//             loading.style.display = 'block';

//             // Muted for banner autoplay
//             video.muted = true;

//             if (Hls.isSupported()) {
//                 if (hls) {
//                     hls.destroy();
//                 }

//                 hls = new Hls({
//                     enableWorker: true,
//                     lowLatencyMode: true,
//                     backBufferLength: 90
//                 });

//                 hls.loadSource(hlsUrl);
//                 hls.attachMedia(video);

//                 hls.on(Hls.Events.MANIFEST_PARSED, function() {
//                     console.log('HLS manifest parsed - banner');
//                     loading.style.display = 'none';
//                     video.play().catch(e => {
//                         console.log('Banner auto-play failed:', e);
//                     });
//                 });

//                 hls.on(Hls.Events.ERROR, function(event, data) {
//                     console.log('HLS error - banner:', data);
//                     if (data.fatal) {
//                         switch(data.type) {
//                             case Hls.ErrorTypes.NETWORK_ERROR:
//                                 console.log('Network error, retrying...');
//                                 retryStream();
//                                 break;
//                             case Hls.ErrorTypes.MEDIA_ERROR:
//                                 console.log('Media error, recovering...');
//                                 hls.recoverMediaError();
//                                 break;
//                             default:
//                                 console.log('Fatal error, cannot recover');
//                                 showError('Stream error');
//                                 break;
//                         }
//                     }
//                 });

//             } else if (video.canPlayType("application/vnd.apple.mpegurl")) {
//                 video.src = hlsUrl;
//                 video.addEventListener('loadeddata', function() {
//                     loading.style.display = 'none';
//                     video.play().catch(e => {
//                         console.log('Banner auto-play failed:', e);
//                     });
//                 });

//                 video.addEventListener('error', function() {
//                     retryStream();
//                 });
//             } else {
//                 showError('HLS not supported');
//             }

//             video.addEventListener('waiting', function() {
//                 loading.style.display = 'block';
//             });

//             video.addEventListener('playing', function() {
//                 loading.style.display = 'none';
//                 retryCount = 0;
//             });
//         }

//         function retryStream() {
//             if (retryCount < maxRetries) {
//                 retryCount++;
//                 console.log('Retrying banner stream... attempt ' + retryCount);
//                 loading.style.display = 'block';
//                 loading.innerHTML = '<div class="spinner"></div>Reconnecting... (' + retryCount + '/' + maxRetries + ')';

//                 setTimeout(function() {
//                     initializePlayer();
//                 }, 2000);
//             } else {
//                 showError('Failed to connect');
//             }
//         }

//         function showError(message) {
//             loading.style.display = 'none';
//             const errorElement = document.createElement('div');
//             errorElement.id = 'error';
//             errorElement.innerHTML = '❌ ' + message;
//             videoContainer.appendChild(errorElement);
//         }

//         // Initialize when page loads
//         initializePlayer();

//         // Handle visibility changes
//         document.addEventListener('visibilitychange', function() {
//             if (document.hidden) {
//                 video.pause();
//             } else {
//                 video.play().catch(e => console.log('Resume play failed:', e));
//             }
//         });

//         // Prevent right-click menu
//         document.addEventListener('contextmenu', function(e) {
//             e.preventDefault();
//             return false;
//         });
//     </script>
// </body>
// </html>
// ''';
//   }

//   void _reloadBannerStream() {
//     setState(() {
//       _isBannerLoading = true;
//       _hasBannerError = false;
//     });
//     _bannerWebViewController?.reload();
//   }

//   Future<void> _initializePrayerTimes() async {
//     final bool loadedFromCache = await _loadCachedPrayerTimes();
//     if (loadedFromCache) {
//       _updateNextPrayerAndCountdown();
//       setState(() => _isLoadingPrayerTimes = false);
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
//       setState(() {
//         _prayerTimes = {
//           'Fajr': DateTime.parse(decodedTimes['Fajr']),
//           'Dhuhr': DateTime.parse(decodedTimes['Dhuhr']),
//           'Asr': DateTime.parse(decodedTimes['Asr']),
//           'Maghrib': DateTime.parse(decodedTimes['Maghrib']),
//           'Isha': DateTime.parse(decodedTimes['Isha']),
//         };
//       });
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
//       if (permission == LocationPermission.denied)
//         permission = await Geolocator.requestPermission();
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
//         coordinates: Coordinates(lat, lng),
//         date: DateTime.now(),
//         calculationParameters: CalculationMethod.muslimWorldLeague()
//           ..madhab = Madhab.shafi);
//     setState(() {
//       _prayerTimes = {
//         'Fajr': prayerTimesData.fajr!.toLocal(),
//         'Dhuhr': prayerTimesData.dhuhr!.toLocal(),
//         'Asr': prayerTimesData.asr!.toLocal(),
//         'Maghrib': prayerTimesData.maghrib!.toLocal(),
//         'Isha': prayerTimesData.isha!.toLocal(),
//       };
//       _updateNextPrayerAndCountdown();
//       _savePrayerTimes();
//     });
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
//     if (nextPrayerDateTime == null)
//       nextPrayerDateTime = _prayerTimes['Fajr']?.add(const Duration(days: 1));
//     setState(() => _nextPrayerName = nextPrayer);
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

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Minber TV'),
//       ),
//       drawer: const AppDrawer(),
//       body: RefreshIndicator(
//         onRefresh: _refreshData,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildVideoBanner(context),
//               const SizedBox(height: 24),
//               _buildHalalPremium(theme),
//               const SizedBox(height: 24),
//               _buildPrayerTimesSection(theme),
//               const SizedBox(height: 24),
//               _buildSectionHeader(theme, "Explore Our Apps", () {
//                 Navigator.pushNamed(context, '/subapps');
//               }),
//               const SizedBox(height: 12),
//               _buildAppsSection(theme),
//               const SizedBox(height: 24),
//               // =========== CHANGE #1: "View All" now navigates to the new page ===========
//               _buildSectionHeader(theme, "Trending on Minber", () {
//                 // Only navigate if there are videos to show
//                 if (_trendingVideos.isNotEmpty) {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => TrendingSeeAllPage(
//                         trendingVideos: _trendingVideos,
//                       ),
//                     ),
//                   );
//                 }
//               }),
//               const SizedBox(height: 12),
//               _buildTrendingSection(context, theme),
//               const SizedBox(height: 24),
//               _buildSectionHeader(theme, "Latest News", () {}),
//               const SizedBox(height: 12),
//               _buildNewsSection(theme),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: _buildBottomNavigationBar(theme),
//     );
//   }

//   // --- WIDGET BUILDER METHODS (UPDATED SECTION) ---

//   final List<Map<String, dynamic>> _appsData = const [
//     {
//       'name': 'Alfurqan',
//       'image': 'assets/images/alfuqan.jpg',
//       'url': 'https://Skylinkict.com/alfurqan',
//     },
//     {
//       'name': 'Kirbgebeya',
//       'image': 'assets/images/kirbgebeya.png',
//       'url': 'https://kirbgebeya.com/',
//     },
//     {
//       'name': 'Almathurat',
//       'image': 'assets/images/almathurat.jpg',
//       'url': 'https://Skylinkict.com/almathurat',
//     },
//     {
//       'name': 'Besirah',
//       'image': 'assets/images/besira.jpg',
//       'url': null, // This will now navigate to the ComingSoonPage
//     },
//   ];

//   // Updated: Video banner using WebView (No changes here)
//   Widget _buildVideoBanner(BuildContext context) {
//     return AspectRatio(
//       aspectRatio: 16 / 9,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           color: Colors.black,
//           child: Stack(
//             fit: StackFit.expand,
//             children: [
//               // WebView for stream
//               if (_bannerWebViewController != null)
//                 WebViewWidget(controller: _bannerWebViewController!),

//               // Loading overlay
//               if (_isBannerLoading)
//                 Container(
//                   color: Colors.black,
//                   child: const Center(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         CircularProgressIndicator(color: Colors.white),
//                         SizedBox(height: 12),
//                         Text(
//                           'Loading Stream...',
//                           style: TextStyle(color: Colors.white, fontSize: 14),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//               // Error overlay
//               if (_hasBannerError)
//                 Container(
//                   color: Colors.black,
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.error_outline, color: Colors.white, size: 40),
//                       const SizedBox(height: 12),
//                       const Text(
//                         'Stream Error',
//                         style: TextStyle(color: Colors.white, fontSize: 14),
//                       ),
//                       const SizedBox(height: 12),
//                       ElevatedButton.icon(
//                         onPressed: _reloadBannerStream,
//                         icon: Icon(Icons.refresh, size: 16),
//                         label: Text('Retry'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 16, vertical: 8),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//               // Visual elements - Only when stream is working
//               if (!_hasBannerError && !_isBannerLoading) ...[
//                 Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         Colors.black.withOpacity(0.6),
//                         Colors.transparent
//                       ],
//                       begin: Alignment.bottomCenter,
//                       end: Alignment.center,
//                     ),
//                   ),
//                 ),

//                 // LIVE badge
//                 Positioned(
//                   top: 12,
//                   left: 12,
//                   child: Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//                     decoration: BoxDecoration(
//                       color: Colors.red.shade600,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: const Text(
//                       "LIVE",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 ),

//                 // ⭐⭐⭐ MUTE/UNMUTE BUTTON ⭐⭐⭐
//                 Positioned(
//                   top: 12,
//                   right: 12,
//                   child: GestureDetector(
//                     onTap: () {
//                       // Toggle mute in the WebView
//                       final jsCode = """
//                     if (video.muted) {
//                       video.muted = false;
//                       video.volume = 1.0;
//                     } else {
//                       video.muted = true;
//                     }
//                     """;
//                       _bannerWebViewController?.runJavaScript(jsCode);
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.all(6),
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.7),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Icon(
//                         Icons
//                             .volume_off, // Starts muted, so show volume off icon
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                     ),
//                   ),
//                 ),

//                 // ⭐⭐⭐ CLICKABLE "TAP FOR FULL SCREEN" TEXT ⭐⭐⭐
//                 Positioned(
//                   bottom: 12,
//                   right: 12,
//                   child: GestureDetector(
//                     onTap: () => Navigator.pushNamed(context, '/live'),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 10, vertical: 5),
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.7),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Text(
//                         "Tap for full screen →",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Updated: Trending section with API data (No changes here)
//   Widget _buildTrendingSection(BuildContext context, ThemeData theme) {
//     return SizedBox(
//       height: MediaQuery.of(context).size.width * 0.4,
//       child: _isLoadingTrending
//           ? _buildTrendingShimmer(context)
//           : _hasTrendingError
//               ? _buildTrendingError(theme)
//               : _trendingVideos.isEmpty
//                   ? _buildNoTrendingContent(theme)
//                   : ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: _trendingVideos.length,
//                       itemBuilder: (context, index) {
//                         final video = _trendingVideos[index];
//                         return _buildTrendingItem(context, theme, video, index);
//                       },
//                     ),
//     );
//   }

//   Widget _buildTrendingShimmer(BuildContext context) {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: 3,
//         itemBuilder: (context, index) => Container(
//           width: MediaQuery.of(context).size.width * 0.7,
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
//           Text(
//             'Failed to load trending',
//             style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
//           ),
//           const SizedBox(height: 8),
//           ElevatedButton(
//             onPressed: _fetchTrendingVideos,
//             child: const Text('Retry'),
//           ),
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
//           Text(
//             'No trending content',
//             style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
//           ),
//         ],
//       ),
//     );
//   }

//   // =========== CHANGE #2: Trending items are now tappable to play video ===========
//   Widget _buildTrendingItem(
//       BuildContext context, ThemeData theme, dynamic video, int index) {
//     // CORRECTED URL LOGIC
//     String thumbnailUrl = video['thumbnail'] ?? '';
//     if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('http')) {
//       thumbnailUrl = 'http://msa.merkuz.com:3636/$thumbnailUrl';
//     }

//     return Container(
//       width: MediaQuery.of(context).size.width * 0.7,
//       margin: const EdgeInsets.only(right: 12),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         clipBehavior: Clip.antiAlias,
//         child: InkWell(
//           onTap: () {
//             final videoUrl = video['videoUrl'] as String?;
//             if (videoUrl == null || videoUrl.isEmpty) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('No video URL available.')),
//               );
//               return;
//             }

//             // Extract the YouTube Video ID from the URL
//             String? videoId = YoutubePlayer.convertUrlToId(videoUrl);

//             if (videoId != null && videoId.isNotEmpty) {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => VideoPlayerPage(videoId: videoId),
//                 ),
//               );
//             } else {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Could not play video (Invalid URL).'),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//             }
//           },
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Expanded(
//                 flex: 3,
//                 child: thumbnailUrl.isNotEmpty
//                     ? Image.network(
//                         thumbnailUrl,
//                         fit: BoxFit.cover,
//                         loadingBuilder: (context, child, loadingProgress) {
//                           if (loadingProgress == null) return child;
//                           return Center(
//                             child: CircularProgressIndicator(
//                               value: loadingProgress.expectedTotalBytes != null
//                                   ? loadingProgress.cumulativeBytesLoaded /
//                                       loadingProgress.expectedTotalBytes!
//                                   : null,
//                             ),
//                           );
//                         },
//                         errorBuilder: (context, error, stackTrace) {
//                           return Container(
//                             color: theme.cardColor,
//                             child: Icon(
//                               Icons.videocam,
//                               color: theme.hintColor,
//                               size: 40,
//                             ),
//                           );
//                         },
//                       )
//                     : Container(
//                         color: theme.cardColor,
//                         child: Icon(
//                           Icons.videocam,
//                           color: theme.hintColor,
//                           size: 40,
//                         ),
//                       ),
//               ),
//               Expanded(
//                 flex: 1,
//                 child: Container(
//                   padding: const EdgeInsets.all(8),
//                   child: Text(
//                     video['title']?.toString() ?? 'Untitled',
//                     style: theme.textTheme.bodyMedium?.copyWith(
//                       fontWeight: FontWeight.w500,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // (The rest of your widget builder methods are completely unchanged)
//   // ... from _buildAppsSection down to the end of the class.

//   Widget _buildAppsSection(ThemeData theme) {
//     return SizedBox(
//       height: 140,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: _appsData.length,
//         itemBuilder: (context, index) {
//           final app = _appsData[index];
//           return _buildAppCard(theme, app);
//         },
//       ),
//     );
//   }

//   Widget _buildAppCard(ThemeData theme, Map<String, dynamic> app) {
//     return SizedBox(
//       width: 110,
//       child: Card(
//         clipBehavior: Clip.antiAlias,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         elevation: 3,
//         shadowColor: Colors.black.withOpacity(0.2),
//         margin: const EdgeInsets.only(right: 12),
//         child: InkWell(
//           onTap: () {
//             final url = app['url'] as String?;
//             if (url != null) {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => EmbeddedWebScreen(
//                     url: url,
//                     appName: app['name'],
//                   ),
//                 ),
//               );
//             } else {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const ComingSoonPage(),
//                   settings: RouteSettings(
//                     arguments: app['name'],
//                   ),
//                 ),
//               );
//             }
//           },
//           child: Column(
//             children: [
//               Expanded(
//                 flex: 3,
//                 child: Image.asset(
//                   app['image'],
//                   fit: BoxFit.cover,
//                   width: double.infinity,
//                   frameBuilder:
//                       (context, child, frame, wasSynchronouslyLoaded) {
//                     if (wasSynchronouslyLoaded) return child;
//                     return AnimatedOpacity(
//                       opacity: frame == null ? 0 : 1,
//                       duration: const Duration(seconds: 1),
//                       curve: Curves.easeOut,
//                       child: child,
//                     );
//                   },
//                 ),
//               ),
//               Expanded(
//                 flex: 2,
//                 child: Center(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 4.0),
//                     child: Text(
//                       app['name'],
//                       textAlign: TextAlign.center,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: theme.textTheme.bodyMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHalalPremium(ThemeData theme) {
//     return Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//             color: theme.colorScheme.primary.withOpacity(0.08),
//             borderRadius: BorderRadius.circular(16)),
//         child: Row(children: [
//           Expanded(
//               child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                 Text("Halal Premium",
//                     style: theme.textTheme.titleMedium
//                         ?.copyWith(fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 4),
//                 Text("Enjoy ad-free streaming, exclusive content, and more.",
//                     style: theme.textTheme.bodyMedium
//                         ?.copyWith(color: theme.hintColor))
//               ])),
//           const SizedBox(width: 12),
//           ElevatedButton(
//               onPressed: () => Navigator.pushNamed(context, "/subscription"),
//               child: const Text("Upgrade"))
//         ]));
//   }

//   Widget _buildPrayerTimesSection(ThemeData theme) {
//     const prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
//     final timeFormatter = DateFormat("h:mm");
//     final periodFormatter = DateFormat("a");

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (!_isLoadingPrayerTimes)
//           Text("Next: $_nextPrayerName in $_nextPrayerCountdown",
//               style: theme.textTheme.titleMedium?.copyWith(
//                   color: theme.colorScheme.primary,
//                   fontWeight: FontWeight.bold))
//         else
//           Text("Next Prayer",
//               style: theme.textTheme.titleMedium?.copyWith(
//                   color: theme.hintColor, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 12),
//         _isLoadingPrayerTimes
//             ? _buildPrayerTimesShimmer(theme)
//             : Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: prayerOrder.map((prayerName) {
//                   final isActive = _nextPrayerName.contains(prayerName);
//                   final prayerDateTime = _prayerTimes[prayerName];
//                   return _buildPrayerTimeColumn(
//                     theme: theme,
//                     prayerName: prayerName,
//                     time: prayerDateTime != null
//                         ? timeFormatter.format(prayerDateTime)
//                         : "--:--",
//                     period: prayerDateTime != null
//                         ? periodFormatter.format(prayerDateTime)
//                         : "",
//                     isActive: isActive,
//                   );
//                 }).toList(),
//               ),
//       ],
//     );
//   }

//   Widget _buildPrayerTimesShimmer(ThemeData theme) {
//     return Shimmer.fromColors(
//         baseColor: theme.splashColor,
//         highlightColor: theme.cardColor,
//         child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: List.generate(
//                 5,
//                 (_) => Expanded(
//                         child: Column(children: [
//                       Container(
//                           width: 40,
//                           height: 12,
//                           color: Colors.white,
//                           margin: const EdgeInsets.only(bottom: 6)),
//                       Container(width: 50, height: 16, color: Colors.white)
//                     ])))));
//   }

//   Widget _buildPrayerTimeColumn(
//       {required ThemeData theme,
//       required String prayerName,
//       required String time,
//       required String period,
//       required bool isActive}) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//         decoration: isActive
//             ? BoxDecoration(
//                 color: theme.colorScheme.primary,
//                 borderRadius: BorderRadius.circular(12))
//             : null,
//         child: Column(
//           children: [
//             Text(prayerName,
//                 style: theme.textTheme.bodyMedium?.copyWith(
//                     color: isActive
//                         ? theme.colorScheme.onPrimary.withOpacity(0.8)
//                         : theme.hintColor)),
//             const SizedBox(height: 4),
//             Text(time,
//                 style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: isActive
//                         ? theme.colorScheme.onPrimary
//                         : theme.colorScheme.onBackground)),
//             const SizedBox(height: 2),
//             Text(period.toUpperCase(),
//                 style: theme.textTheme.bodySmall?.copyWith(
//                     color: isActive
//                         ? theme.colorScheme.onPrimary.withOpacity(0.8)
//                         : theme.hintColor)),
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
//       TextButton(onPressed: onViewAll, child: const Text("View All"))
//     ]);
//   }

//   Widget _buildNewsSection(ThemeData theme) {
//     final List<Map<String, String>> news = [
//       {
//         "title": "Global Relief Efforts Intensify for Recent Disaster",
//         "time": "2h ago",
//         "image": "assets/images/news1.png"
//       },
//       {
//         "title": "New Grand Mosque Opening in Addis Ababa Next Week",
//         "time": "5h ago",
//         "image": "assets/images/news2.png"
//       },
//       {
//         "title": "Minber App Reaches 1 Million Downloads",
//         "time": "1d ago",
//         "image": "assets/images/news3.png"
//       },
//     ];
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: news.length,
//       itemBuilder: (context, index) {
//         final item = news[index];
//         return Card(
//           elevation: 0,
//           color: theme.cardColor,
//           margin: const EdgeInsets.symmetric(vertical: 6),
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           child: InkWell(
//             borderRadius: BorderRadius.circular(12),
//             onTap: () {},
//             child: Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: Row(
//                 children: [
//                   ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.asset(item['image']!,
//                           width: 70, height: 70, fit: BoxFit.cover)),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           item["title"]!,
//                           style: theme.textTheme.bodyLarge
//                               ?.copyWith(fontWeight: FontWeight.bold),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           item["time"]!,
//                           style: theme.textTheme.bodySmall
//                               ?.copyWith(color: theme.hintColor),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   BottomNavigationBar _buildBottomNavigationBar(ThemeData theme) {
//     return BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         selectedItemColor: theme.colorScheme.primary,
//         unselectedItemColor: theme.unselectedWidgetColor,
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: theme.cardColor,
//         elevation: 5,
//         items: const [
//           BottomNavigationBarItem(
//               icon: Icon(Icons.home_outlined),
//               activeIcon: Icon(Icons.home),
//               label: "Home"),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.tv_outlined),
//               activeIcon: Icon(Icons.tv),
//               label: "Media"),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.mosque_outlined),
//               activeIcon: Icon(Icons.mosque),
//               label: "Prayer"),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.chat_bubble_outline),
//               activeIcon: Icon(Icons.chat_bubble),
//               label: "Chat Bot"),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.apps_outlined),
//               activeIcon: Icon(Icons.apps),
//               label: "Sub Apps"),
//         ]);
//   }
// }

// // =========== CHANGE #3: ADDED THE "SEE ALL" PAGE WIDGET BELOW ===========

// class TrendingSeeAllPage extends StatelessWidget {
//   final List<dynamic> trendingVideos;

//   const TrendingSeeAllPage({super.key, required this.trendingVideos});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Trending on Minber'),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(12.0),
//         itemCount: trendingVideos.length,
//         itemBuilder: (context, index) {
//           final video = trendingVideos[index];
//           return _buildTrendingListItem(context, video);
//         },
//       ),
//     );
//   }

//   Widget _buildTrendingListItem(BuildContext context, dynamic video) {
//     final theme = Theme.of(context);
//     String thumbnailUrl = video['thumbnail'] ?? '';
//     if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('http')) {
//       thumbnailUrl = 'http://msa.merkuz.com:3636/$thumbnailUrl';
//     }

//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       clipBehavior: Clip.antiAlias,
//       child: InkWell(
//         onTap: () {
//           final videoUrl = video['videoUrl'] as String?;
//           if (videoUrl == null || videoUrl.isEmpty) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('No video URL available.')),
//             );
//             return;
//           }

//           String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
//           if (videoId != null && videoId.isNotEmpty) {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => VideoPlayerPage(videoId: videoId),
//               ),
//             );
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Could not play video (Invalid URL).'),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//         },
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               width: 140,
//               height: 85,
//               child: thumbnailUrl.isNotEmpty
//                   ? Image.network(
//                       thumbnailUrl,
//                       fit: BoxFit.cover,
//                       errorBuilder: (c, e, s) => Container(
//                         color: Colors.grey[300],
//                         child:
//                             const Icon(Icons.broken_image, color: Colors.grey),
//                       ),
//                     )
//                   : Container(
//                       color: Colors.grey[300],
//                       child:
//                           const Icon(Icons.ondemand_video, color: Colors.grey),
//                     ),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(12.0),
//                 child: Text(
//                   video['title'] ?? 'Untitled',
//                   maxLines: 3,
//                   overflow: TextOverflow.ellipsis,
//                   style: theme.textTheme.bodyMedium
//                       ?.copyWith(fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // =========== CHANGE #4: ADDED THE VIDEO PLAYER PAGE WIDGET BELOW ===========

// class VideoPlayerPage extends StatefulWidget {
//   final String videoId;
//   const VideoPlayerPage({super.key, required this.videoId});

//   @override
//   State<VideoPlayerPage> createState() => _VideoPlayerPageState();
// }

// class _VideoPlayerPageState extends State<VideoPlayerPage> {
//   late YoutubePlayerController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = YoutubePlayerController(
//       initialVideoId: widget.videoId,
//       flags: const YoutubePlayerFlags(
//         autoPlay: true,
//         mute: false,
//       ),
//     );
//   }

//   @override
//   void deactivate() {
//     _controller.pause();
//     super.deactivate();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return YoutubePlayerBuilder(
//       onExitFullScreen: () {
//         SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//       },
//       player: YoutubePlayer(
//         controller: _controller,
//         showVideoProgressIndicator: true,
//       ),
//       builder: (context, player) => Scaffold(
//         appBar: AppBar(
//           title: const Text("Video Player"),
//         ),
//         body: Center(
//           child: player,
//         ),
//       ),
//     );
//   }
// }
// lib/screens/home_screen.dart (Updated with Trending Functionality)
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- REQUIRED for Video Player
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // <-- REQUIRED for Video Player
import '../widgets/app_drawer.dart';
import './coming_soon_page.dart';

// (The EmbeddedWebScreen widget remains the same as before)
class EmbeddedWebScreen extends StatefulWidget {
  final String url;
  final String appName;

  const EmbeddedWebScreen(
      {super.key, required this.url, required this.appName});

  @override
  State<EmbeddedWebScreen> createState() => _EmbeddedWebScreenState();
}

class _EmbeddedWebScreenState extends State<EmbeddedWebScreen> {
  late final WebViewController _controller;
  double _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100.0;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: _loadingProgress > 0 && _loadingProgress < 1
              ? LinearProgressIndicator(value: _loadingProgress)
              : const SizedBox.shrink(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Timer? _timer;

  // Updated: WebView for banner stream
  WebViewController? _bannerWebViewController;
  bool _isBannerLoading = true;
  bool _hasBannerError = false;
  bool _isMuted = true;
  final String streamUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

  String _nextPrayerName = "";
  String _nextPrayerCountdown = "--:--:--";
  Map<String, DateTime> _prayerTimes = {};
  bool _isLoadingPrayerTimes = true;

  // New: Trending API integration
  List<dynamic> _trendingVideos = [];
  bool _isLoadingTrending = true;
  bool _hasTrendingError = false;
  // CORRECTED URL
  final String _trendingApiUrl = 'http://msa.merkuz.com:3636/trending';

  // --- CORE LOGIC (UNCHANGED) ---

  @override
  void initState() {
    super.initState();
    _initializeBannerWebView();
    _initializePrayerTimes();
    _fetchTrendingVideos(); // New: Fetch trending videos
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_prayerTimes.isNotEmpty) _updateCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerWebViewController = null;
    super.dispose();
  }

  // ⭐⭐⭐ ADDED: Method to handle live page navigation ⭐⭐⭐
  void _navigateToLivePage() async {
    // Pause the banner stream before navigating
    if (_bannerWebViewController != null) {
      await _bannerWebViewController?.runJavaScript("video.pause();");
    }

    Navigator.pushNamed(context, '/live').then((_) {
      // Resume the stream when returning from live page
      if (_bannerWebViewController != null && mounted) {
        // Add a small delay to ensure WebView is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _bannerWebViewController?.runJavaScript(
              "video.play().catch(e => console.log('Resume failed:', e));");
        });
      }
    });
  }

  // New: Fetch trending videos from API
  Future<void> _fetchTrendingVideos() async {
    try {
      final response = await http.get(
        Uri.parse(_trendingApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Parse the response - it appears to be a JSON array
        final List<dynamic> responseData = json.decode(response.body);

        setState(() {
          _trendingVideos = responseData;
          _isLoadingTrending = false;
          _hasTrendingError = false;
        });
      } else {
        throw Exception(
            'Failed to load trending videos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching trending videos: $e');
      setState(() {
        _isLoadingTrending = false;
        _hasTrendingError = true;
      });
    }
  }

  // Updated: Refresh data to include trending videos
  Future<void> _refreshData() async {
    await _getLocationAndPrayerTimes();
    await _fetchTrendingVideos(); // Refresh trending videos too
  }

  // (The rest of your core logic remains completely unchanged)
  // ... from _initializeBannerWebView down to _onItemTapped
  Future<void> _initializeBannerWebView() async {
    try {
      final htmlContent = _createBannerHtml();

      final PlatformWebViewControllerCreationParams params;

      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      _bannerWebViewController =
          WebViewController.fromPlatformCreationParams(params)
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(Colors.black)
            ..enableZoom(false)
            ..setNavigationDelegate(
              NavigationDelegate(
                onProgress: (int progress) {
                  if (progress > 80) {
                    setState(() {
                      _isBannerLoading = false;
                    });
                  }
                },
                onPageFinished: (String url) {
                  setState(() {
                    _isBannerLoading = false;
                  });
                },
                onWebResourceError: (WebResourceError error) {
                  setState(() {
                    _hasBannerError = true;
                    _isBannerLoading = false;
                  });
                },
              ),
            );

      if (_bannerWebViewController!.platform is AndroidWebViewController) {
        final AndroidWebViewController androidController =
            _bannerWebViewController!.platform as AndroidWebViewController;
        androidController.setMediaPlaybackRequiresUserGesture(false);
      }

      _bannerWebViewController!.loadHtmlString(htmlContent);
    } catch (e) {
      setState(() {
        _hasBannerError = true;
        _isBannerLoading = false;
      });
    }
  }

  String _createBannerHtml() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Live Stream</title>
    <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            margin: 0;
            background: #000000;
            overflow: hidden;
            width: 100vw;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }
        #videoContainer {
            width: 100%;
            height: 100%;
            position: relative;
            background: #000;
        }
        #video {
            width: 100%;
            height: 100%;
            object-fit: cover;
            background: #000;
        }
        #loading {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: white;
            font-size: 14px;
            text-align: center;
            z-index: 10;
        }
        .spinner {
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top: 2px solid #ffffff;
            width: 30px;
            height: 30px;
            animation: spin 1s linear infinite;
            margin: 0 auto 10px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        #error {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: white;
            text-align: center;
            background: rgba(255, 0, 0, 0.1);
            padding: 15px;
            border-radius: 8px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            font-size: 12px;
        }
        #status {
            position: absolute;
            top: 10px;
            left: 10px;
            background: rgba(0, 0, 0, 0.7);
            color: white;
            padding: 6px 12px;
            borderRadius: 16px;
            font-size: 12px;
            z-index: 5;
            backdrop-filter: blur(10px);
        }
    </style>
</head>
<body>
    <div id="videoContainer">
        <div id="loading">
            <div class="spinner"></div>
            Loading stream...
        </div>
        <video id="video" muted autoplay playsinline></video>
        <div id="status">🔴 LIVE</div>
    </div>

    <script>
        const video = document.getElementById("video");
        const videoContainer = document.getElementById("videoContainer");
        const loading = document.getElementById("loading");
        const status = document.getElementById("status");
        const hlsUrl = "$streamUrl";

        let hls;
        let retryCount = 0;
        const maxRetries = 3;

        function initializePlayer() {
            loading.style.display = 'block';
            
            // Muted for banner autoplay
            video.muted = true;
            
            if (Hls.isSupported()) {
                if (hls) {
                    hls.destroy();
                }
                
                hls = new Hls({
                    enableWorker: true,
                    lowLatencyMode: true,
                    backBufferLength: 90
                });
                
                hls.loadSource(hlsUrl);
                hls.attachMedia(video);
                
                hls.on(Hls.Events.MANIFEST_PARSED, function() {
                    console.log('HLS manifest parsed - banner');
                    loading.style.display = 'none';
                    video.play().catch(e => {
                        console.log('Banner auto-play failed:', e);
                    });
                });
                
                hls.on(Hls.Events.ERROR, function(event, data) {
                    console.log('HLS error - banner:', data);
                    if (data.fatal) {
                        switch(data.type) {
                            case Hls.ErrorTypes.NETWORK_ERROR:
                                console.log('Network error, retrying...');
                                retryStream();
                                break;
                            case Hls.ErrorTypes.MEDIA_ERROR:
                                console.log('Media error, recovering...');
                                hls.recoverMediaError();
                                break;
                            default:
                                console.log('Fatal error, cannot recover');
                                showError('Stream error');
                                break;
                        }
                    }
                });
                
            } else if (video.canPlayType("application/vnd.apple.mpegurl")) {
                video.src = hlsUrl;
                video.addEventListener('loadeddata', function() {
                    loading.style.display = 'none';
                    video.play().catch(e => {
                        console.log('Banner auto-play failed:', e);
                    });
                });
                
                video.addEventListener('error', function() {
                    retryStream();
                });
            } else {
                showError('HLS not supported');
            }

            video.addEventListener('waiting', function() {
                loading.style.display = 'block';
            });
            
            video.addEventListener('playing', function() {
                loading.style.display = 'none';
                retryCount = 0;
            });
        }

        function retryStream() {
            if (retryCount < maxRetries) {
                retryCount++;
                console.log('Retrying banner stream... attempt ' + retryCount);
                loading.style.display = 'block';
                loading.innerHTML = '<div class="spinner"></div>Reconnecting... (' + retryCount + '/' + maxRetries + ')';
                
                setTimeout(function() {
                    initializePlayer();
                }, 2000);
            } else {
                showError('Failed to connect');
            }
        }

        function showError(message) {
            loading.style.display = 'none';
            const errorElement = document.createElement('div');
            errorElement.id = 'error';
            errorElement.innerHTML = '❌ ' + message;
            videoContainer.appendChild(errorElement);
        }

        // Initialize when page loads
        initializePlayer();

        // Handle visibility changes
        document.addEventListener('visibilitychange', function() {
            if (document.hidden) {
                video.pause();
            } else {
                video.play().catch(e => console.log('Resume play failed:', e));
            }
        });

        // Prevent right-click menu
        document.addEventListener('contextmenu', function(e) {
            e.preventDefault();
            return false;
        });
    </script>
</body>
</html>
''';
  }

  void _reloadBannerStream() {
    setState(() {
      _isBannerLoading = true;
      _hasBannerError = false;
    });
    _bannerWebViewController?.reload();
  }

  // ⭐⭐⭐ ADDED: Toggle mute method ⭐⭐⭐
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });

    // Send command to WebView to toggle mute
    final jsCode = _isMuted
        ? "video.muted = true;"
        : "video.muted = false; video.volume = 1.0;";
    _bannerWebViewController?.runJavaScript(jsCode);
  }

  Future<void> _initializePrayerTimes() async {
    final bool loadedFromCache = await _loadCachedPrayerTimes();
    if (loadedFromCache) {
      _updateNextPrayerAndCountdown();
      setState(() => _isLoadingPrayerTimes = false);
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
              _buildSectionHeader(theme, "Explore Our Apps", () {
                Navigator.pushNamed(context, '/subapps');
              }),
              const SizedBox(height: 12),
              _buildAppsSection(theme),
              const SizedBox(height: 24),
              // =========== CHANGE #1: "View All" now navigates to the new page ===========
              _buildSectionHeader(theme, "Trending on Minber", () {
                // Only navigate if there are videos to show
                if (_trendingVideos.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrendingSeeAllPage(
                        trendingVideos: _trendingVideos,
                      ),
                    ),
                  );
                }
              }),
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

  // --- WIDGET BUILDER METHODS (UPDATED SECTION) ---

  final List<Map<String, dynamic>> _appsData = const [
    {
      'name': 'Alfurqan',
      'image': 'assets/images/alfuqan.jpg',
      'url': 'https://Skylinkict.com/alfurqan',
    },
    {
      'name': 'Kirbgebeya',
      'image': 'assets/images/kirbgebeya.png',
      'url': 'https://kirbgebeya.com/',
    },
    {
      'name': 'Almathurat',
      'image': 'assets/images/almathurat.jpg',
      'url': 'https://Skylinkict.com/almathurat',
    },
    {
      'name': 'Besirah',
      'image': 'assets/images/besira.jpg',
      'url': null, // This will now navigate to the ComingSoonPage
    },
  ];

  // Updated: Video banner using WebView with navigation fix
  Widget _buildVideoBanner(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // WebView for stream
              if (_bannerWebViewController != null)
                WebViewWidget(controller: _bannerWebViewController!),

              // Loading overlay
              if (_isBannerLoading)
                Container(
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'Loading Stream...',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

              // Error overlay
              if (_hasBannerError)
                Container(
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Stream Error',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _reloadBannerStream,
                        icon: Icon(Icons.refresh, size: 16),
                        label: Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),

              // Visual elements - Only when stream is working
              if (!_hasBannerError && !_isBannerLoading) ...[
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                    ),
                  ),
                ),

                // LIVE badge
               
                // ⭐⭐⭐ MUTE/UNMUTE BUTTON - NOW UPDATES VISUALLY ⭐⭐⭐
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _toggleMute,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // ⭐⭐⭐ CLICKABLE "TAP FOR FULL SCREEN" TEXT - UPDATED TO USE NEW METHOD ⭐⭐⭐
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap:
                        _navigateToLivePage, // ⭐ CHANGED TO USE THE NEW METHOD ⭐
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Tap for full screen →",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Updated: Trending section with API data (No changes here)
  Widget _buildTrendingSection(BuildContext context, ThemeData theme) {
    return SizedBox(
      height: MediaQuery.of(context).size.width * 0.4,
      child: _isLoadingTrending
          ? _buildTrendingShimmer(context)
          : _hasTrendingError
              ? _buildTrendingError(theme)
              : _trendingVideos.isEmpty
                  ? _buildNoTrendingContent(theme)
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _trendingVideos.length,
                      itemBuilder: (context, index) {
                        final video = _trendingVideos[index];
                        return _buildTrendingItem(context, theme, video, index);
                      },
                    ),
    );
  }

  Widget _buildTrendingShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: MediaQuery.of(context).size.width * 0.7,
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
          Text(
            'Failed to load trending',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchTrendingVideos,
            child: const Text('Retry'),
          ),
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
          Text(
            'No trending content',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  // =========== CHANGE #2: Trending items are now tappable to play video ===========
  Widget _buildTrendingItem(
      BuildContext context, ThemeData theme, dynamic video, int index) {
    // CORRECTED URL LOGIC
    String thumbnailUrl = video['thumbnail'] ?? '';
    if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('http')) {
      thumbnailUrl = 'http://msa.merkuz.com:3636/$thumbnailUrl';
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            final videoUrl = video['videoUrl'] as String?;
            if (videoUrl == null || videoUrl.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No video URL available.')),
              );
              return;
            }

            // Extract the YouTube Video ID from the URL
            String? videoId = YoutubePlayer.convertUrlToId(videoUrl);

            if (videoId != null && videoId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerPage(videoId: videoId),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not play video (Invalid URL).'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: thumbnailUrl.isNotEmpty
                    ? Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.cardColor,
                            child: Icon(
                              Icons.videocam,
                              color: theme.hintColor,
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: theme.cardColor,
                        child: Icon(
                          Icons.videocam,
                          color: theme.hintColor,
                          size: 40,
                        ),
                      ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    video['title']?.toString() ?? 'Untitled',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (The rest of your widget builder methods are completely unchanged)
  // ... from _buildAppsSection down to the end of the class.

  Widget _buildAppsSection(ThemeData theme) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _appsData.length,
        itemBuilder: (context, index) {
          final app = _appsData[index];
          return _buildAppCard(theme, app);
        },
      ),
    );
  }

  Widget _buildAppCard(ThemeData theme, Map<String, dynamic> app) {
    return SizedBox(
      width: 110,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.2),
        margin: const EdgeInsets.only(right: 12),
        child: InkWell(
          onTap: () {
            final url = app['url'] as String?;
            if (url != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmbeddedWebScreen(
                    url: url,
                    appName: app['name'],
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ComingSoonPage(),
                  settings: RouteSettings(
                    arguments: app['name'],
                  ),
                ),
              );
            }
          },
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Image.asset(
                  app['image'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      app['name'],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: isActive
            ? BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12))
            : null,
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
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
      TextButton(onPressed: onViewAll, child: const Text("View All"))
    ]);
  }

  Widget _buildNewsSection(ThemeData theme) {
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
              label: "Sub Apps"),
        ]);
  }
}

// =========== CHANGE #3: ADDED THE "SEE ALL" PAGE WIDGET BELOW ===========

class TrendingSeeAllPage extends StatelessWidget {
  final List<dynamic> trendingVideos;

  const TrendingSeeAllPage({super.key, required this.trendingVideos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending on Minber'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: trendingVideos.length,
        itemBuilder: (context, index) {
          final video = trendingVideos[index];
          return _buildTrendingListItem(context, video);
        },
      ),
    );
  }

  Widget _buildTrendingListItem(BuildContext context, dynamic video) {
    final theme = Theme.of(context);
    String thumbnailUrl = video['thumbnail'] ?? '';
    if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('http')) {
      thumbnailUrl = 'http://msa.merkuz.com:3636/$thumbnailUrl';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final videoUrl = video['videoUrl'] as String?;
          if (videoUrl == null || videoUrl.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No video URL available.')),
            );
            return;
          }

          String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
          if (videoId != null && videoId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoPlayerPage(videoId: videoId),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not play video (Invalid URL).'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              height: 85,
              child: thumbnailUrl.isNotEmpty
                  ? Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[300],
                        child:
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child:
                          const Icon(Icons.ondemand_video, color: Colors.grey),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  video['title'] ?? 'Untitled',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========== CHANGE #4: ADDED THE VIDEO PLAYER PAGE WIDGET BELOW ===========

class VideoPlayerPage extends StatefulWidget {
  final String videoId;
  const VideoPlayerPage({super.key, required this.videoId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
      ),
      builder: (context, player) => Scaffold(
        appBar: AppBar(
          title: const Text("Video Player"),
        ),
        body: Center(
          child: player,
        ),
      ),
    );
  }
}
