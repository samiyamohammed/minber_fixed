// import 'package:flutter/material.dart';
// import '../core/app_colors.dart';

// class MediaHubPage extends StatefulWidget {
//   const MediaHubPage({super.key});

//   @override
//   State<MediaHubPage> createState() => _MediaHubPageState();
// }

// class _MediaHubPageState extends State<MediaHubPage> {
//   int _selectedIndex = 1; // 👈 Default = Media tab

//   void _onItemTapped(int index) {
//     if (_selectedIndex == index) return;

//     setState(() {
//       _selectedIndex = index;
//     });

//     switch (index) {
//       case 0:
//         Navigator.pushReplacementNamed(context, '/home');
//         break;
//       case 1:
//         // already here
//         break;
//       case 2:
//         Navigator.pushReplacementNamed(context, '/prayer');
//         break;
//       case 3:
//         Navigator.pushReplacementNamed(context, '/chatBot');
//         break;
//       case 4:
//         Navigator.pushReplacementNamed(context, '/subapps');
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Media Hub",
//           style: TextStyle(
//             fontSize: size.width * 0.05,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
//         foregroundColor:
//             theme.appBarTheme.foregroundColor ?? theme.primaryColorLight,
//         elevation: 1,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.notifications_none, size: size.width * 0.065),
//             onPressed: () => Navigator.pushNamed(context, "/notifications"),
//           ),
//           Padding(
//             padding: EdgeInsets.only(right: size.width * 0.03),
//             child: CircleAvatar(
//               radius: size.width * 0.05,
//               backgroundImage: const AssetImage("assets/images/profile.jpg"),
//             ),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
//           child: ListView(
//             children: [
//               SizedBox(height: size.height * 0.02),

//               // 🔹 Menu Cards
//               _buildMenuCard(
//                 size: size,
//                 theme: theme,
//                 icon: Icons.live_tv_outlined,
//                 title: "Live Streaming",
//                 subtitle: "Access real-time broadcasts and events.",
//                 onTap: () => Navigator.pushNamed(context, '/live'),
//               ),
//               SizedBox(height: size.height * 0.018),

//               _buildMenuCard(
//                 size: size,
//                 theme: theme,
//                 icon: Icons.ondemand_video_outlined,
//                 title: "YouTube Integration",
//                 subtitle: "Browse, watch, and manage YouTube content.",
//                 onTap: () => Navigator.pushNamed(context, '/youtube'),
//               ),
//               SizedBox(height: size.height * 0.018),

//               _buildMenuCard(
//                 size: size,
//                 theme: theme,
//                 icon: Icons.history_toggle_off,
//                 title: "Recent & Past TV Shows",
//                 subtitle: "On-demand library with past and recent TV shows.",
//                 onTap: () => Navigator.pushNamed(context, '/ondemand'),
//               ),

//               SizedBox(height: size.height * 0.025),
//             ],
//           ),
//         ),
//       ),

//       // 🔹 Bottom Navigation
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         selectedItemColor: AppColors.primary,
//         unselectedItemColor: theme.unselectedWidgetColor,
//         type: BottomNavigationBarType.fixed,
//         // backgroundColor: theme.bottomAppBarColor,
//         selectedFontSize: size.width * 0.032,
//         unselectedFontSize: size.width * 0.03,
//         iconSize: size.width * 0.06,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
//           BottomNavigationBarItem(icon: Icon(Icons.tv), label: "Media"),
//           BottomNavigationBarItem(icon: Icon(Icons.mosque), label: "Prayer"),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat_bubble_outline),
//             activeIcon: Icon(Icons.chat_bubble),
//             label: "ChatBot",
//           ),
//           BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Sub Apps"),
//         ],
//       ),
//     );
//   }

//   // 🔹 Themed Menu Card
//   Widget _buildMenuCard({
//     required Size size,
//     required ThemeData theme,
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       shadowColor: theme.shadowColor.withOpacity(0.05),
//       color: theme.cardColor,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: onTap,
//         child: Padding(
//           padding: EdgeInsets.all(size.width * 0.045),
//           child: Row(
//             children: [
//               // Icon in circle
//               Container(
//                 width: size.width * 0.13,
//                 height: size.width * 0.13,
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withOpacity(0.15),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   icon,
//                   color: AppColors.primary,
//                   size: size.width * 0.065,
//                 ),
//               ),
//               SizedBox(width: size.width * 0.05),

//               // Texts
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: size.width * 0.045,
//                         fontWeight: FontWeight.w600,
//                         color: theme.textTheme.bodyLarge?.color,
//                       ),
//                     ),
//                     SizedBox(height: size.height * 0.005),
//                     Text(
//                       subtitle,
//                       style: TextStyle(
//                         fontSize: size.width * 0.034,
//                         color: theme.textTheme.bodyMedium?.color?.withOpacity(
//                           0.7,
//                         ),
//                         height: 1.3,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               Icon(
//                 Icons.chevron_right,
//                 color: theme.iconTheme.color?.withOpacity(0.7),
//                 size: size.width * 0.07,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../core/app_colors.dart';

// --- Data Models and API Service (Now part of MediaHubPage) ---

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
      throw Exception('Failed to load playlists: $e');
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
    // 1. Change TabController length to 3
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1: // Already here
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/prayer');
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Media Hub"),
        elevation: 1,
        // 2. Update the TabBar with three tabs
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "All Videos"),
            Tab(text: "Playlists"),
            Tab(text: "On-Demand"),
          ],
        ),
      ),
      // 3. Update the TabBarView with three children
      body: TabBarView(
        controller: _tabController,
        children: [
          const AllVideosTab(),
          const PlaylistsTab(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off,
                    size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text("On-Demand TV Shows",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "This section will contain a library of past and recent TV shows.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
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

// --- Child Tab Widgets (Now part of the same file) ---

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

// --- Reusable UI and Player Page Widgets ---

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
                      width: 150,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                          width: 150,
                          height: 90,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey)),
                    ),
                  )
                else
                  Container(
                      width: 150,
                      height: 90,
                      color: Colors.grey[300],
                      child: const Icon(Icons.ondemand_video)),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(video.title,
                        maxLines: 3, overflow: TextOverflow.ellipsis),
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
                  child: Text(playlist.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0)
                      .copyWith(bottom: 8.0),
                  child: Text('${playlist.itemCount} videos',
                      style: Theme.of(context).textTheme.bodySmall),
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
          showControls: true, showFullscreenButton: true),
    )..setFullScreenListener(
        (isFullScreen) {
          if (mounted) {
            if (isFullScreen) {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight
              ]);
            } else {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown
              ]);
            }
          }
        },
      );
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
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: const Text("Video Player")),
          body: Center(child: player),
        );
      },
    );
  }
}
