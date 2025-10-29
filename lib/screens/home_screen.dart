// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../core/app_colors.dart';
import '../models/video_model.dart'; // Import the Video model
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  Timer? _timer;
  Timer? _autoRefreshTimer;

  // Banner State
  WebViewController? _bannerWebViewController;
  bool _isBannerLoading = true;
  bool _hasBannerError = false;
  bool _isMuted = true;
  final String streamUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

  // Prayer Times State
  String _nextPrayerName = "";
  String _nextPrayerCountdown = "--:--:--";
  Map<String, DateTime> _prayerTimes = {};
  bool _isLoadingPrayerTimes = true;

  // Trending & News State (with Enhanced Caching Logic)
  List<dynamic>? _trendingVideos;
  List<dynamic>? _newsArticles;
  String? _trendingError;
  String? _newsError;

  static const _trendingCacheKey = 'home_trending_cache';
  static const _newsCacheKey = 'home_news_cache';
  static const _trendingTimestampKey = 'home_trending_timestamp';
  static const _newsTimestampKey = 'home_news_timestamp';
  static const _cacheValidityMinutes = 5; // Cache for 5 minutes only

  final String _trendingApiUrl = 'http://msa.merkuz.com:3636/trending';
  final String _newsApiUrl = 'http://msa.merkuz.com:3636/news';
  final String _apiBaseUrl = 'http://msa.merkuz.com:3636';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeBannerWebView();
    _initializePrayerTimes();
    _loadDataWithCache();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_prayerTimes.isNotEmpty) _updateCountdown();
    });

    // Auto-refresh every 10 minutes
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _refreshData();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground, refresh data to ensure it's up-to-date
      _refreshData();
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _bannerWebViewController = null;
    super.dispose();
  }

  // --- ENHANCED DATA FETCHING & CACHING ---

  Future<void> _loadDataWithCache() async {
    final prefs = await SharedPreferences.getInstance();

    // Check trending cache
    final lastTrendingTime = prefs.getInt(_trendingTimestampKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final shouldUseTrendingCache =
        (now - lastTrendingTime) < (_cacheValidityMinutes * 60 * 1000);

    if (shouldUseTrendingCache && mounted) {
      final cachedTrending = prefs.getString(_trendingCacheKey);
      if (cachedTrending != null) {
        setState(() {
          _trendingVideos = json.decode(cachedTrending);
        });
      }
    } else {
      await prefs.remove(_trendingCacheKey);
    }

    // Check news cache
    final lastNewsTime = prefs.getInt(_newsTimestampKey) ?? 0;
    final shouldUseNewsCache =
        (now - lastNewsTime) < (_cacheValidityMinutes * 60 * 1000);

    if (shouldUseNewsCache && mounted) {
      final cachedNews = prefs.getString(_newsCacheKey);
      if (cachedNews != null) {
        setState(() {
          _newsArticles = json.decode(cachedNews);
        });
      }
    } else {
      await prefs.remove(_newsCacheKey);
    }

    // Always fetch fresh data in background
    await _fetchTrendingVideos();
    await _fetchNewsArticles();
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear all cached data to force fresh fetch
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

    // Refresh all data sources from network
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

        // Save to cache with timestamp
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

        // Save to cache with timestamp
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

  // --- PRAYER TIMES & BANNER METHODS ---

  void _navigateToLivePage() async {
    if (_bannerWebViewController != null) {
      await _bannerWebViewController?.runJavaScript("video.pause();");
    }

    Navigator.pushNamed(context, '/live').then((_) {
      if (_bannerWebViewController != null && mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _bannerWebViewController?.runJavaScript(
              "video.play().catch(e => console.log('Resume failed:', e));");
        });
      }
    });
  }

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
                  if (progress > 80 && mounted) {
                    setState(() => _isBannerLoading = false);
                  }
                },
                onPageFinished: (String url) {
                  if (mounted) setState(() => _isBannerLoading = false);
                },
                onWebResourceError: (WebResourceError error) {
                  if (mounted) {
                    setState(() {
                      _hasBannerError = true;
                      _isBannerLoading = false;
                    });
                  }
                },
              ),
            );

      if (_bannerWebViewController!.platform is AndroidWebViewController) {
        (_bannerWebViewController!.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }

      await _bannerWebViewController!.loadHtmlString(htmlContent);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasBannerError = true;
          _isBannerLoading = false;
        });
      }
    }
  }

  String _createBannerHtml() {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
        <style>
            body, html { margin: 0; padding: 0; width: 100%; height: 100%; background-color: #000; overflow: hidden; }
            video { width: 100%; height: 100%; object-fit: cover; }
        </style>
    </head>
    <body>
        <video id="video" muted autoplay playsinline></video>
        <script>
            const video = document.getElementById('video');
            const hlsUrl = "$streamUrl";
            if (Hls.isSupported()) {
                const hls = new Hls();
                hls.loadSource(hlsUrl);
                hls.attachMedia(video);
                hls.on(Hls.Events.MANIFEST_PARSED, function() {
                    video.play().catch(e => console.error("Autoplay failed", e));
                });
            } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
                video.src = hlsUrl;
                video.addEventListener('loadedmetadata', function() {
                    video.play().catch(e => console.error("Autoplay failed", e));
                });
            }
            document.addEventListener('contextmenu', event => event.preventDefault());
        </script>
    </body>
    </html>
    ''';
  }

  void _reloadBannerStream() {
    if (mounted) {
      setState(() {
        _isBannerLoading = true;
        _hasBannerError = false;
      });
    }
    _bannerWebViewController?.reload();
  }

  void _toggleMute() {
    if (mounted) {
      setState(() {
        _isMuted = !_isMuted;
      });
    }
    final jsCode = _isMuted
        ? "video.muted = true;"
        : "video.muted = false; video.volume = 1.0;";
    _bannerWebViewController?.runJavaScript(jsCode);
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
      // Handle location error silently
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

  // --- NAVIGATION & HELPERS ---

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
      'url': null,
    },
  ];

  String _formatTimeAgo(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}y ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}mo ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return ''; // Return empty string if date is invalid
    }
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    const double bannerHeight = 220.0;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        const double flingVelocity = 400.0;
        if ((details.primaryVelocity ?? 0).abs() > flingVelocity) {
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
                      background: _buildVideoBanner(context),
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
                              Navigator.pushNamed(
                                context,
                                '/news',
                                arguments: {
                                  'newsArticles': _newsArticles,
                                  'apiBaseUrl': _apiBaseUrl,
                                },
                              );
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

  // --- BUILD WIDGETS ---

  Widget _buildVideoBanner(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_bannerWebViewController != null)
            WebViewWidget(controller: _bannerWebViewController!),
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
                    "Tap for full screen →",
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
                        Text(
                          'Next Prayer: $_nextPrayerName',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue),
                        ),
                        Text(
                          'in $_nextPrayerCountdown',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

    final activeColor = AppColors.primaryBlue;
    final inactiveColor = theme.textTheme.bodyMedium?.color;
    final inactiveHintColor = theme.hintColor;

    return Column(
      children: [
        Text(
          prayerName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? activeColor : inactiveColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          timeString,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? activeColor : inactiveColor,
          ),
          textAlign: TextAlign.center,
        ),
        if (periodString.isNotEmpty)
          Text(
            periodString,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isActive ? activeColor : inactiveHintColor,
            ),
          ),
      ],
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
          ),
        ),
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

    // FIXED: Proper URL construction
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
              const SnackBar(content: Text('No video URL available.')),
            );
            return;
          }

          String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
          if (videoId != null && videoId.isNotEmpty) {
            // --- START: MODIFICATION ---

            // 1. Convert the dynamic list to a List<Video>
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
              );
            }).toList();

            // 2. Navigate with all the required parameters
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
            // --- END: MODIFICATION ---
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Could not play video (Invalid URL).')),
            );
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl.isNotEmpty)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: theme.splashColor),
              )
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
              colors: [
                AppColors.primaryBlue,
                AppColors.accentBlue,
              ],
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
            CircleAvatar(
              radius: 35,
              backgroundImage: AssetImage(app['image']),
            ),
            const SizedBox(height: 8),
            Text(
              app['name'],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
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
        final newsCard = Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withOpacity(0.8)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (newsUrl != null && newsUrl.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmbeddedWebScreen(
                      url: newsUrl,
                      appName: headline,
                    ),
                  ),
                );
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
                        Text(
                          headline,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTimeAgo(item["createdAt"] ?? ''),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: thumbnailUrl.isNotEmpty
                        ? Image.network(
                            thumbnailUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 80,
                              height: 80,
                              color: theme.splashColor,
                              child: const Icon(Icons.broken_image, size: 30),
                            ),
                          )
                        : Container(
                            width: 80,
                            height: 80,
                            color: theme.splashColor,
                            child: const Icon(Icons.image, size: 30),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
        return AnimatedListItem(
          index: index,
          child: newsCard,
        );
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
        border: Border(
          top: BorderSide(color: theme.dividerColor, width: 1.0),
        ),
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
