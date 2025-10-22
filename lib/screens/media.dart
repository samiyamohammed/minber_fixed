// lib/screens/media.dart (Final Version with Blocklist)
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Keep for potential future use
import 'package:pretty_http_logger/pretty_http_logger.dart';
import 'package:shimmer/shimmer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// --- Data Models (No Changes) ---
class Video {
  final String id, videoId, title, thumbnailUrl, category, privacyStatus;
  final DateTime publishedAt;

  Video({
    required this.id,
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.category,
    required this.privacyStatus,
    required this.publishedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) => Video(
        id: json['id'] ?? '',
        videoId: json['videoId'] ?? '',
        title: json['title'] ?? 'Untitled',
        thumbnailUrl: json['thumbnailUrl1'] ?? json['thumbnailUrl'] ?? '',
        category: json['category'] ?? json['playlist']?['title'] ?? 'Other',
        privacyStatus: json['privacyStatus'] ?? 'public',
        publishedAt:
            DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime(1970),
      );
}

class Playlist {
  final String id, playlistId, title, thumbnailUrl;
  final int itemCount;
  Playlist(
      {required this.id,
      required this.playlistId,
      required this.title,
      required this.thumbnailUrl,
      required this.itemCount});
  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
      id: json['id'] ?? '',
      playlistId: json['playlistId'] ?? '',
      title: json['title'] ?? 'Untitled',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      itemCount: json['itemCount'] ?? 0);
}

// --- ApiService (UPDATED with Blocklist) ---
class ApiService {
  final String baseUrl = "http://msa.merkuz.com:3636/youtube";

  // ⭐⭐⭐ ADDED: Blocklist for specific problematic video IDs ⭐⭐⭐
  final List<String> _videoBlocklist = [
    'clRQNP4RdUA',
  ];

  static final http.Client _client = HttpClientWithMiddleware.build(
    middlewares: [
      HttpLogger(logLevel: LogLevel.BODY),
    ],
  );

  Future<List<Video>> getVideos({String? category}) async {
    String url = "$baseUrl/videos";
    if (category != null) {
      url = "$url?category=${Uri.encodeComponent(category)}";
    }
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      List<Video> videos =
          (data['data'] as List).map((json) => Video.fromJson(json)).toList();

      // Apply all filters and sorting
      videos = _filterAndSortVideos(videos);

      return videos;
    } else {
      throw Exception('Failed to load videos');
    }
  }

  Future<List<Video>> getVideosFromPlaylistSlug(String slug) async {
    final response = await _client.get(Uri.parse("$baseUrl/playlists/$slug"));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      List<Video> videos =
          (data['data'] as List).map((json) => Video.fromJson(json)).toList();

      // Apply all filters and sorting
      videos = _filterAndSortVideos(videos);

      return videos;
    } else {
      throw Exception('Failed to load playlist videos');
    }
  }

  // ⭐⭐⭐ ADDED: Centralized filtering and sorting logic ⭐⭐⭐
  List<Video> _filterAndSortVideos(List<Video> videos) {
    // 1. Apply the blocklist FIRST
    List<Video> filteredList = videos
        .where((video) => !_videoBlocklist.contains(video.videoId))
        .toList();

    // 2. Filter for public status
    filteredList =
        filteredList.where((video) => video.privacyStatus == 'public').toList();

    // 3. Sort by newest date
    filteredList.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    return filteredList;
  }

  Future<List<Playlist>> getPlaylists() async {
    final response = await _client.get(Uri.parse("$baseUrl/playlists"));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      List<Playlist> playlists = (data['data'] as List)
          .map((json) => Playlist.fromJson(json))
          .toList();
      int targetIndex = playlists.indexWhere((p) =>
          p.title.toLowerCase().contains('minber') &&
          p.title.toLowerCase().contains('kheber'));
      if (targetIndex > 0) {
        playlists.insert(0, playlists.removeAt(targetIndex));
      }
      return playlists;
    } else {
      throw Exception('Failed to load playlists');
    }
  }
}

// --- MediaHubPage (No Changes) ---
class MediaHubPage extends StatefulWidget {
  const MediaHubPage({super.key});
  @override
  State<MediaHubPage> createState() => _MediaHubPageState();
}

class _MediaHubPageState extends State<MediaHubPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showComingSoonSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _ComingSoonSheetContent(),
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    String routeName = '';
    switch (index) {
      case 0:
        routeName = '/home';
        break;
      case 1:
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
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3.0,
                onTap: (index) {
                  if (index == 2) {
                    _showComingSoonSheet();
                    _tabController.animateTo(_tabController.previousIndex);
                  }
                },
                tabs: const [
                  Tab(text: "All Videos"),
                  Tab(text: "Playlists"),
                  Tab(text: "On-Demand"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    const AllVideosTab(),
                    const PlaylistsTab(),
                    Container(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
              label: "ChatBot"),
          BottomNavigationBarItem(
              icon: Icon(Icons.apps_outlined),
              activeIcon: Icon(Icons.apps),
              label: "Sub Apps"),
        ],
      ),
    );
  }
}

// --- Child Tab Widgets (No Changes) ---
class AllVideosTab extends StatefulWidget {
  const AllVideosTab({super.key});
  @override
  State<AllVideosTab> createState() => _AllVideosTabState();
}

class _AllVideosTabState extends State<AllVideosTab> {
  final ApiService _apiService = ApiService();
  late Future<List<Video>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _videosFuture = _apiService.getVideos();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Video>>(
      future: _videosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _VideoListShimmer();
        }
        if (snapshot.hasError) {
          developer.log('Error fetching videos: ${snapshot.error}');
          return _EmptyState(
              icon: Icons.error_outline,
              message: "An Error Occurred",
              description:
                  "Could not load videos. Please check your connection.");
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/coming-soon',
              arguments:
                  'Videos Library', // This will be received as featureName
            ),
            child: const _EmptyState(
              icon: Icons.videocam_off_outlined,
              message: "No Videos Found",
              description: "There are currently no videos available.",
            ),
          );
        }
        final videos = snapshot.data!;
        return VideoListView(videos: videos);
      },
    );
  }
}

class PlaylistsTab extends StatefulWidget {
  const PlaylistsTab({super.key});
  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  final ApiService _apiService = ApiService();
  Playlist? _selectedPlaylist;
  Future<List<dynamic>>? _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _apiService.getPlaylists();
  }

  void _onPlaylistTapped(Playlist playlist) {
    setState(() {
      _selectedPlaylist = playlist;
      final slug = playlist.title.toLowerCase().contains('minber') &&
              playlist.title.toLowerCase().contains('kheber')
          ? 'minber-kheber'
          : null;
      _dataFuture = slug != null
          ? _apiService.getVideosFromPlaylistSlug(slug)
          : _apiService.getVideos(category: playlist.title);
    });
  }

  void _backToPlaylists() {
    setState(() {
      _selectedPlaylist = null;
      _dataFuture = _apiService.getPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_selectedPlaylist != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Playlists'),
                onPressed: _backToPlaylists,
              ),
            ),
          ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _selectedPlaylist == null
                    ? const _PlaylistGridShimmer()
                    : const _VideoListShimmer();
              }
              if (snapshot.hasError) {
                return _EmptyState(
                    icon: Icons.error_outline,
                    message: "An Error Occurred",
                    description:
                        "Could not load content. Please check your connection.");
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _EmptyState(
                  icon: _selectedPlaylist == null
                      ? Icons.playlist_remove_rounded
                      : Icons.videocam_off_outlined,
                  message: _selectedPlaylist == null
                      ? "No Playlists Found"
                      : "No Videos Found",
                  description: _selectedPlaylist == null
                      ? "There are no playlists available right now."
                      : "This playlist is currently empty.",
                );
              }
              if (_selectedPlaylist == null) {
                final playlists = snapshot.data!.cast<Playlist>();
                return PlaylistGridView(
                    playlists: playlists, onPlaylistTapped: _onPlaylistTapped);
              } else {
                final videos = snapshot.data!.cast<Video>();
                return VideoListView(videos: videos);
              }
            },
          ),
        ),
      ],
    );
  }
}

// --- VideoListView (UPDATED - Removed date display) ---
class VideoListView extends StatelessWidget {
  final List<Video> videos;
  final bool enableNavigation;

  const VideoListView(
      {super.key, required this.videos, this.enableNavigation = true});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          color: Theme.of(context).cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enableNavigation
                ? () {
                    final rawVideoId = video.videoId.trim();
                    String? finalVideoId =
                        YoutubePlayer.convertUrlToId(rawVideoId);

                    finalVideoId ??= rawVideoId;

                    if (finalVideoId.isNotEmpty) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => VideoPlayerPage(
                                    videoId: finalVideoId!,
                                    initialVideo: video,
                                    videoList: videos,
                                    initialIndex: index,
                                  )));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Could not play video (Invalid Video ID).'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                : null,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  height: 80,
                  child: video.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          video.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image,
                                size: 40, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.ondemand_video)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      video.title,
                      maxLines: 3, // Allow up to 3 lines for the title
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// (The rest of the file remains unchanged from the previous version)

class PlaylistGridView extends StatelessWidget {
  final List<Playlist> playlists;
  final Function(Playlist) onPlaylistTapped;
  const PlaylistGridView(
      {super.key, required this.playlists, required this.onPlaylistTapped});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          color: Theme.of(context).cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => onPlaylistTapped(playlist),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (playlist.thumbnailUrl.isNotEmpty)
                  Image.network(playlist.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Center(
                            child: Icon(Icons.broken_image,
                                size: 50, color: Colors.grey[400]),
                          ))
                else
                  Container(
                      color: Colors.grey,
                      child: const Icon(Icons.video_library)),
                Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent
                ], begin: Alignment.bottomCenter, end: Alignment.center))),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(playlist.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${playlist.itemCount} videos',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  final String videoId;
  final Video? initialVideo;
  final List<Video>? videoList;
  final int? initialIndex;

  const VideoPlayerPage({
    super.key,
    required this.videoId,
    this.initialVideo,
    this.videoList,
    this.initialIndex,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;
  final ApiService _apiService = ApiService();
  late Future<List<Video>> _relatedVideosFuture;
  Video? _currentVideoDetails;
  int _currentVideoIndex = 0;
  List<Video> _allVideos = [];
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        enableCaption: true,
        useHybridComposition: true,
        forceHD: true,
      ),
    );

    _controller.addListener(_handlePlayerErrors);

    _currentVideoDetails = widget.initialVideo;
    _relatedVideosFuture = _apiService.getVideos();
    _initializeVideoData();

    _controller.addListener(() {
      if (_controller.value.isReady &&
          _currentVideoDetails?.title == null &&
          _controller.metadata.title.isNotEmpty) {
        setState(() {
          _currentVideoDetails = Video(
            id: _controller.metadata.videoId,
            videoId: _controller.metadata.videoId,
            title: _controller.metadata.title,
            thumbnailUrl: YoutubePlayer.getThumbnail(
                videoId: _controller.metadata.videoId,
                quality: ThumbnailQuality.high),
            category: 'YouTube',
            privacyStatus: 'public',
            publishedAt: DateTime.now(),
          );
        });
      }
    });
  }

  void _handlePlayerErrors() {
    if (mounted && _controller.value.hasError) {
      developer.log('YouTube Player Error: ${_controller.value.errorCode}');
      if (_controller.value.errorCode == 150) {
        _controller.removeListener(_handlePlayerErrors);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playback unavailable. Skipping to next video.'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          _playNextVideo();
          _controller.addListener(_handlePlayerErrors);
        });
      }
    }
  }

  void _initializeVideoData() async {
    try {
      if (widget.videoList != null && widget.videoList!.isNotEmpty) {
        _allVideos = widget.videoList!;
        _currentVideoIndex = widget.initialIndex ??
            _allVideos.indexWhere((video) => video.videoId == widget.videoId);
        if (_currentVideoIndex < 0) _currentVideoIndex = 0;
      } else {
        final relatedVideos = await _relatedVideosFuture;
        _allVideos = relatedVideos;
        _currentVideoIndex =
            _allVideos.indexWhere((video) => video.videoId == widget.videoId);
        if (_currentVideoIndex < 0) _currentVideoIndex = 0;
      }
    } catch (e) {
      print('Error initializing video data: $e');
    }
  }

  void _playNextVideo() {
    if (!mounted || _allVideos.isEmpty) return;
    int nextIndex = (_currentVideoIndex + 1) % _allVideos.length;
    _playVideoAtIndex(nextIndex);
  }

  void _playPreviousVideo() {
    if (!mounted || _allVideos.isEmpty) return;
    int prevIndex = (_currentVideoIndex - 1) % _allVideos.length;
    if (prevIndex < 0) prevIndex = _allVideos.length - 1;
    _playVideoAtIndex(prevIndex);
  }

  void _playVideoAtIndex(int index) {
    if (!mounted || index < 0 || index >= _allVideos.length) return;
    final video = _allVideos[index];
    setState(() {
      _currentVideoIndex = index;
      _currentVideoDetails = video;
      _controller.load(video.videoId);
      _controller.play();
    });
  }

  void _playVideo(Video video) {
    final index = _allVideos.indexWhere((v) => v.videoId == video.videoId);
    if (index != -1) {
      _playVideoAtIndex(index);
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  Widget _buildFullScreenButton() {
    return IconButton(
      icon: Icon(
        _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
        color: Colors.white,
      ),
      onPressed: _toggleFullScreen,
    );
  }

  @override
  void dispose() {
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    _controller.removeListener(_handlePlayerErrors);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: _isFullScreen
            ? null
            : AppBar(
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                centerTitle: true),
        body: _isFullScreen ? _buildFullScreenPlayer() : _buildNormalLayout(),
      ),
    );
  }

  Widget _buildFullScreenPlayer() {
    return Container(
      color: Colors.black,
      child: Center(
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.red,
          progressColors: const ProgressBarColors(
            playedColor: Colors.red,
            handleColor: Colors.red,
          ),
          bottomActions: [
            CurrentPosition(),
            ProgressBar(isExpanded: true),
            RemainingDuration(),
            _buildFullScreenButton(),
          ],
          onEnded: (metaData) {
            _playNextVideo();
          },
        ),
      ),
    );
  }

  Widget _buildNormalLayout() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Theme.of(context).colorScheme.primary,
            progressColors: ProgressBarColors(
              playedColor: Theme.of(context).colorScheme.primary,
              handleColor: Theme.of(context).colorScheme.primary,
            ),
            bottomActions: [
              CurrentPosition(),
              ProgressBar(isExpanded: true),
              RemainingDuration(),
              _buildFullScreenButton(),
            ],
            onEnded: (metaData) {
              _playNextVideo();
            },
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _currentVideoDetails?.title ?? "Loading Video Title...",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        "Up Next",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_allVideos.length} videos',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                _RelatedVideosList(
                  relatedVideosFuture: _relatedVideosFuture,
                  onVideoTap: _playVideo,
                  currentVideoId: _currentVideoDetails?.videoId,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RelatedVideosList extends StatelessWidget {
  final Future<List<Video>> relatedVideosFuture;
  final Function(Video)? onVideoTap;
  final String? currentVideoId;

  const _RelatedVideosList({
    required this.relatedVideosFuture,
    this.onVideoTap,
    this.currentVideoId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Video>>(
      future: relatedVideosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Error loading videos',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          );
        }

        final videos = snapshot.data ?? [];
        if (videos.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No videos available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ),
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: videos.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final video = videos[index];
            final isCurrentVideo = video.videoId == currentVideoId;

            return _VideoCard(
              video: video,
              isPlaying: isCurrentVideo,
              onTap: () => onVideoTap?.call(video),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
            3,
            (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ShimmerVideoCard(),
                )),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Video video;
  final bool isPlaying;
  final VoidCallback? onTap;

  const _VideoCard({
    required this.video,
    this.isPlaying = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPlaying
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
            color: isPlaying
                ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                : Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(video.thumbnailUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: isPlaying
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.7),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            height: 1.3,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (isPlaying) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Now Playing',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerVideoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoListShimmer extends StatelessWidget {
  const _VideoListShimmer();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.splashColor.withOpacity(0.3),
      highlightColor: theme.cardColor.withOpacity(0.3),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 140, height: 80, color: Colors.white),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white),
                      const SizedBox(height: 8),
                      Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 100, height: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistGridShimmer extends StatelessWidget {
  const _PlaylistGridShimmer();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.splashColor.withOpacity(0.3),
      highlightColor: theme.cardColor.withOpacity(0.3),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0),
        itemCount: 6,
        itemBuilder: (context, index) => Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String description;

  const _EmptyState(
      {required this.icon, required this.message, required this.description});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: theme.hintColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(message,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor)),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonSheetContent extends StatelessWidget {
  const _ComingSoonSheetContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded,
              size: 60, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text("Feature Coming Soon!",
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              "The On-Demand TV Shows library is under construction. We're working hard to bring it to you!",
              textAlign: TextAlign.center,
              style:
                  theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Got It")),
        ],
      ),
    );
  }
}
