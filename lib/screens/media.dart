// lib/screens/media_hub_page.dart (Fully Corrected & Ready to Paste)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

// --- Data Models and API Service (No Changes Needed) ---
class Video {
  final String id, videoId, title, thumbnailUrl, category;
  Video(
      {required this.id,
      required this.videoId,
      required this.title,
      required this.thumbnailUrl,
      required this.category});
  factory Video.fromJson(Map<String, dynamic> json) => Video(
      id: json['id'] ?? '',
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? 'Untitled',
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnailUrl1'] ?? '',
      category: json['category'] ?? json['playlist']?['title'] ?? 'Other');
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

class ApiService {
  final String baseUrl = "http://msa.merkuz.com:3636/youtube";
  Future<List<Video>> getVideos({String? category}) async {
    String url = "$baseUrl/videos";
    if (category != null)
      url = "$url?category=${Uri.encodeComponent(category)}";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return (data['data'] as List)
          .map((json) => Video.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load videos');
    }
  }

  Future<List<Video>> getVideosFromPlaylistSlug(String slug) async {
    final response = await http.get(Uri.parse("$baseUrl/playlists/$slug"));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return (data['data'] as List)
          .map((json) => Video.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load playlist videos');
    }
  }

  Future<List<Playlist>> getPlaylists() async {
    final response = await http.get(Uri.parse("$baseUrl/playlists"));
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

// --- MediaHubPage (Main Widget) ---
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
    if (routeName.isNotEmpty)
      Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Media Hub"),
        // ✅ CORRECTION: Explicitly setting the AppBar and TabBar colors for this page
        backgroundColor: theme.colorScheme.primary,
        foregroundColor:
            theme.colorScheme.onPrimary, // Ensures title and icons are white
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // Selected tab text is white
          unselectedLabelColor: Colors.white
              .withOpacity(0.7), // Unselected is slightly transparent white
          indicatorColor: Colors.white, // Underline is white
          indicatorWeight: 3.0,
          tabs: const [
            Tab(text: "All Videos"),
            Tab(text: "Playlists"),
            Tab(text: "On-Demand"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const AllVideosTab(),
          const PlaylistsTab(),
          _EmptyState(
              icon: Icons.history_toggle_off_outlined,
              message: "On-Demand TV Shows",
              description:
                  "This section will contain a library of past and recent TV shows."),
        ],
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

// --- Child Tab Widgets (No changes needed, but included for completeness) ---
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
          return _EmptyState(
              icon: Icons.error_outline,
              message: "An Error Occurred",
              description:
                  "Could not load videos. Please check your connection.");
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const _EmptyState(
              icon: Icons.videocam_off_outlined,
              message: "No Videos Found",
              description: "There are currently no videos available.");
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
                label: Text('Back to Playlists'),
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

// --- Reusable UI and Player Page Widgets (No changes needed) ---
class VideoListView extends StatelessWidget {
  final List<Video> videos;
  const VideoListView({super.key, required this.videos});

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
            onTap: () {
              if (video.videoId.isNotEmpty)
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            VideoPlayerPage(videoId: video.videoId)));
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  height: 80,
                  child: video.thumbnailUrl.isNotEmpty
                      ? Image.network(video.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.broken_image))
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.ondemand_video)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(video.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
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
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
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
                      errorBuilder: (c, e, s) =>
                          const Center(child: Icon(Icons.broken_image)))
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
  const VideoPlayerPage({super.key, required this.videoId});
  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
            showControls: true, showFullscreenButton: true))
      ..setFullScreenListener((isFullScreen) {
        if (mounted) {
          if (isFullScreen) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight
            ]);
          } else {
            SystemChrome.setPreferredOrientations(
                [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
          }
        }
      });
  }

  @override
  void dispose() {
    _controller.close();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _controller,
      aspectRatio: 16 / 9,
      builder: (context, player) => Scaffold(
          appBar: AppBar(title: const Text("Video Player")),
          body: Center(child: player)),
    );
  }
}

class _VideoListShimmer extends StatelessWidget {
  const _VideoListShimmer();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.splashColor,
      highlightColor: theme.cardColor,
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
      baseColor: theme.splashColor,
      highlightColor: theme.cardColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
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
