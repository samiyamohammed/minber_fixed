import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import this for orientation controls
import 'package:http/http.dart' as http;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

// --- Data Models for your API ---

class Video {
  final String id;
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final String category;

  Video({
    required this.id,
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.category,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? '',
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? 'Untitled Video',
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnailUrl1'] ?? '',
      category: json['category'] ?? json['playlist']?['title'] ?? 'Other',
    );
  }
}

class Playlist {
  final String id;
  final String playlistId;
  final String title;
  final String thumbnailUrl;
  final int itemCount;

  Playlist({
    required this.id,
    required this.playlistId,
    required this.title,
    required this.thumbnailUrl,
    required this.itemCount,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      playlistId: json['playlistId'] ?? '',
      title: json['title'] ?? 'Untitled Playlist',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      itemCount: json['itemCount'] ?? 0,
    );
  }
}

// --- API Service to talk to your backend ---

class ApiService {
  final String baseUrl = "http://msa.merkuz.com:3636/youtube";

  Future<List<Video>> getVideos({String? category}) async {
    String url = "$baseUrl/videos";
    if (category != null) {
      url = "$url?category=${Uri.encodeComponent(category)}";
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> videoData = data['data'];
        return videoData.map((json) => Video.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load videos (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print("Error fetching videos: $e");
      throw Exception('Failed to load videos: $e');
    }
  }

  Future<List<Video>> getVideosFromPlaylistSlug(String slug) async {
    final String url = "$baseUrl/playlists/$slug";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> videoData = data['data'];
        return videoData.map((json) => Video.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load playlist videos (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print("Error fetching videos from playlist slug '$slug': $e");
      throw Exception('Failed to load playlist videos: $e');
    }
  }

  Future<List<Playlist>> getPlaylists() async {
    final String url = "$baseUrl/playlists";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> playlistData = data['data'];
        List<Playlist> playlists =
            playlistData.map((json) => Playlist.fromJson(json)).toList();

        int targetIndex = playlists.indexWhere((p) {
          final lowerCaseTitle = p.title.toLowerCase();
          return lowerCaseTitle.contains('minber') &&
              lowerCaseTitle.contains('kheber');
        });

        if (targetIndex > 0) {
          final targetPlaylist = playlists.removeAt(targetIndex);
          playlists.insert(0, targetPlaylist);
        }

        return playlists;
      } else {
        throw Exception(
            'Failed to load playlists (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print("Error fetching playlists: $e");
      throw Exception('Failed to load playlists: $e');
    }
  }
}

// --- Main Page with Tabs ---

class YouTubePage extends StatelessWidget {
  const YouTubePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Media'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Videos'),
              Tab(text: 'Playlists'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AllVideosTab(),
            PlaylistsTab(),
          ],
        ),
      ),
    );
  }
}

// --- "All Videos" Tab Widget ---

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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No videos found.'));
        }

        final videos = snapshot.data!;
        return VideoListView(videos: videos);
      },
    );
  }
}

// --- "Playlists" Tab Widget ---

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

      final lowerCaseTitle = playlist.title.toLowerCase();
      if (lowerCaseTitle.contains('minber') &&
          lowerCaseTitle.contains('kheber')) {
        _dataFuture = _apiService.getVideosFromPlaylistSlug('minber-kheber');
      } else {
        _dataFuture = _apiService.getVideos(category: playlist.title);
      }
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
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.arrow_back),
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
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Text(_selectedPlaylist == null
                        ? 'No playlists found.'
                        : 'No videos found in this playlist.'));
              }

              if (_selectedPlaylist == null) {
                final playlists = snapshot.data!.cast<Playlist>();
                return PlaylistGridView(
                  playlists: playlists,
                  onPlaylistTapped: _onPlaylistTapped,
                );
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

// --- Reusable UI Components ---

class VideoListView extends StatelessWidget {
  final List<Video> videos;
  const VideoListView({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return GestureDetector(
          onTap: () {
            if (video.videoId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => VideoPlayerPage(videoId: video.videoId)),
              );
            }
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (video.thumbnailUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12)),
                    child: Image.network(
                      video.thumbnailUrl,
                      width: size.width * 0.35,
                      height: size.width * 0.22,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: size.width * 0.35,
                        height: size.width * 0.22,
                        color: Colors.grey[300],
                        child:
                            const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Container(
                    width: size.width * 0.35,
                    height: size.width * 0.22,
                    color: Colors.grey[300],
                    child: const Icon(Icons.ondemand_video),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    child: Text(
                      video.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
        childAspectRatio: 16 / 12,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return GestureDetector(
          onTap: () => onPlaylistTapped(playlist),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: playlist.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          playlist.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image)),
                        )
                      : Container(
                          color: Colors.grey,
                          child: const Icon(Icons.video_library)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    playlist.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0)
                      .copyWith(bottom: 8.0),
                  child: Text(
                    '${playlist.itemCount} videos',
                    style: Theme.of(context).textTheme.bodySmall,
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

// --- UPDATED Video Player Page ---

class VideoPlayerPage extends StatefulWidget {
  final String videoId;
  const VideoPlayerPage({super.key, required this.videoId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        enableJavaScript: true,
      ),
    )..setFullScreenListener(
        (isFullScreen) {
          if (mounted) {
            if (isFullScreen) {
              // When entering fullscreen, force landscape
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]);
            } else {
              // When exiting fullscreen, force portrait
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
            }
          }
        },
      );
  }

  @override
  void dispose() {
    _controller.close();
    // IMPORTANT: Always reset orientation when leaving the page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using YoutubePlayerScaffold to handle the fullscreen UI transition smoothly
    return YoutubePlayerScaffold(
      controller: _controller,
      aspectRatio: 16 / 9,
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Video Player"),
          ),
          body: Center(
            // Place the player provided by the builder
            child: player,
          ),
        );
      },
    );
  }
}
