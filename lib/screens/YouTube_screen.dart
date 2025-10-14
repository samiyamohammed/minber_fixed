// // import 'dart:convert';
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:shimmer/shimmer.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // THE CORRECT IMPORT

// // --- Data Models and API Service (Unchanged) ---
// class Video {
//   final String id, videoId, title, thumbnailUrl, category;
//   Video(
//       {required this.id,
//       required this.videoId,
//       required this.title,
//       required this.thumbnailUrl,
//       required this.category});
//   factory Video.fromJson(Map<String, dynamic> json) => Video(
//       id: json['id'] ?? '',
//       videoId: json['videoId'] ?? '',
//       title: json['title'] ?? 'Untitled',
//       thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnailUrl1'] ?? '',
//       category: json['category'] ?? json['playlist']?['title'] ?? 'Other');
// }

// class Playlist {
//   final String id, playlistId, title, thumbnailUrl;
//   final int itemCount;
//   Playlist(
//       {required this.id,
//       required this.playlistId,
//       required this.title,
//       required this.thumbnailUrl,
//       required this.itemCount});
//   factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
//       id: json['id'] ?? '',
//       playlistId: json['playlistId'] ?? '',
//       title: json['title'] ?? 'Untitled',
//       thumbnailUrl: json['thumbnailUrl'] ?? '',
//       itemCount: json['itemCount'] ?? 0);
// }

// class ApiService {
//   final String baseUrl = "http://msa.merkuz.com:3636/youtube";
//   Future<List<Video>> getVideos({String? category}) async {
//     String url = "$baseUrl/videos";
//     if (category != null)
//       url = "$url?category=${Uri.encodeComponent(category)}";
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode == 200) {
//       final data = json.decode(utf8.decode(response.bodyBytes));
//       return (data['data'] as List)
//           .map((json) => Video.fromJson(json))
//           .toList();
//     } else {
//       throw Exception('Failed to load videos');
//     }
//   }

//   Future<List<Video>> getVideosFromPlaylistSlug(String slug) async {
//     final response = await http.get(Uri.parse("$baseUrl/playlists/$slug"));
//     if (response.statusCode == 200) {
//       final data = json.decode(utf8.decode(response.bodyBytes));
//       return (data['data'] as List)
//           .map((json) => Video.fromJson(json))
//           .toList();
//     } else {
//       throw Exception('Failed to load playlist videos');
//     }
//   }

//   Future<List<Playlist>> getPlaylists() async {
//     final response = await http.get(Uri.parse("$baseUrl/playlists"));
//     if (response.statusCode == 200) {
//       final data = json.decode(utf8.decode(response.bodyBytes));
//       List<Playlist> playlists = (data['data'] as List)
//           .map((json) => Playlist.fromJson(json))
//           .toList();
//       int targetIndex = playlists.indexWhere((p) =>
//           p.title.toLowerCase().contains('minber') &&
//           p.title.toLowerCase().contains('kheber'));
//       if (targetIndex > 0) {
//         playlists.insert(0, playlists.removeAt(targetIndex));
//       }
//       return playlists;
//     } else {
//       throw Exception('Failed to load playlists');
//     }
//   }
// }

// // --- Main Page with Tabs - NAME CORRECTED ---
// class YouTubePage extends StatelessWidget {
//   const YouTubePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('YouTube Content'),
//           bottom: TabBar(
//             labelColor: theme.colorScheme.primary,
//             unselectedLabelColor: theme.unselectedWidgetColor,
//             indicatorColor: theme.colorScheme.primary,
//             indicatorWeight: 3.0,
//             tabs: const [
//               Tab(text: 'All Videos'),
//               Tab(text: 'Playlists'),
//             ],
//           ),
//         ),
//         body: const TabBarView(
//           children: [AllVideosTab(), PlaylistsTab()],
//         ),
//       ),
//     );
//   }
// }

// // --- "All Videos" Tab Widget ---
// class AllVideosTab extends StatefulWidget {
//   const AllVideosTab({super.key});
//   @override
//   State<AllVideosTab> createState() => _AllVideosTabState();
// }

// class _AllVideosTabState extends State<AllVideosTab> {
//   final ApiService _apiService = ApiService();
//   late Future<List<Video>> _videosFuture;

//   @override
//   void initState() {
//     super.initState();
//     _videosFuture = _apiService.getVideos();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<Video>>(
//       future: _videosFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const _VideoListShimmer();
//         }
//         if (snapshot.hasError) {
//           return const _EmptyState(
//               icon: Icons.error_outline,
//               message: "An Error Occurred",
//               description: "Could not load videos.");
//         }
//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const _EmptyState(
//               icon: Icons.videocam_off_outlined,
//               message: "No Videos Found",
//               description: "There are no videos available right now.");
//         }
//         return VideoListView(videos: snapshot.data!);
//       },
//     );
//   }
// }

// // --- "Playlists" Tab Widget ---
// class PlaylistsTab extends StatefulWidget {
//   const PlaylistsTab({super.key});
//   @override
//   State<PlaylistsTab> createState() => _PlaylistsTabState();
// }

// class _PlaylistsTabState extends State<PlaylistsTab> {
//   final ApiService _apiService = ApiService();
//   Playlist? _selectedPlaylist;
//   Future<List<dynamic>>? _dataFuture;

//   @override
//   void initState() {
//     super.initState();
//     _dataFuture = _apiService.getPlaylists();
//   }

//   void _onPlaylistTapped(Playlist playlist) {
//     setState(() {
//       _selectedPlaylist = playlist;
//       final slug = playlist.title.toLowerCase().contains('minber') &&
//               playlist.title.toLowerCase().contains('kheber')
//           ? 'minber-kheber'
//           : null;
//       _dataFuture = slug != null
//           ? _apiService.getVideosFromPlaylistSlug(slug)
//           : _apiService.getVideos(category: playlist.title);
//     });
//   }

//   void _backToPlaylists() {
//     setState(() {
//       _selectedPlaylist = null;
//       _dataFuture = _apiService.getPlaylists();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         if (_selectedPlaylist != null)
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//             child: Align(
//               alignment: Alignment.centerLeft,
//               child: ActionChip(
//                 avatar: const Icon(Icons.arrow_back, size: 18),
//                 label: Text(_selectedPlaylist!.title,
//                     overflow: TextOverflow.ellipsis),
//                 onPressed: _backToPlaylists,
//               ),
//             ),
//           ),
//         Expanded(
//           child: FutureBuilder<List<dynamic>>(
//             future: _dataFuture,
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return _selectedPlaylist == null
//                     ? const _PlaylistGridShimmer()
//                     : const _VideoListShimmer();
//               }
//               if (snapshot.hasError) {
//                 return const _EmptyState(
//                     icon: Icons.error_outline,
//                     message: "An Error Occurred",
//                     description: "Could not load content.");
//               }
//               if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                 return _EmptyState(
//                   icon: _selectedPlaylist == null
//                       ? Icons.playlist_remove_rounded
//                       : Icons.videocam_off_outlined,
//                   message: _selectedPlaylist == null
//                       ? "No Playlists Found"
//                       : "No Videos Found",
//                   description: _selectedPlaylist == null
//                       ? "Playlists will appear here."
//                       : "This playlist is currently empty.",
//                 );
//               }
//               if (_selectedPlaylist == null) {
//                 return PlaylistGridView(
//                     playlists: snapshot.data!.cast<Playlist>(),
//                     onPlaylistTapped: _onPlaylistTapped);
//               } else {
//                 return VideoListView(videos: snapshot.data!.cast<Video>());
//               }
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// // --- Reusable UI Components ---
// class VideoListView extends StatelessWidget {
//   final List<Video> videos;
//   const VideoListView({super.key, required this.videos});

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: videos.length,
//       itemBuilder: (context, index) {
//         final video = videos[index];
//         return Card(
//           elevation: 0,
//           margin: const EdgeInsets.only(bottom: 16),
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           clipBehavior: Clip.antiAlias,
//           child: InkWell(
//             onTap: () {
//               final rawVideoId = video.videoId.trim();
//               String? finalVideoId = YoutubePlayer.convertUrlToId(rawVideoId);
//               finalVideoId ??= rawVideoId;

//               if (finalVideoId.isNotEmpty)
//                 Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (_) =>
//                             VideoPlayerPage(videoId: finalVideoId!)));
//             },
//             child: Row(
//               children: [
//                 SizedBox(
//                   width: 140,
//                   height: 80,
//                   child: video.thumbnailUrl.isNotEmpty
//                       ? Image.network(video.thumbnailUrl,
//                           fit: BoxFit.cover,
//                           errorBuilder: (c, e, s) =>
//                               const Icon(Icons.broken_image))
//                       : Container(
//                           color: Colors.grey[300],
//                           child: const Icon(Icons.ondemand_video)),
//                 ),
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Text(video.title,
//                         maxLines: 3,
//                         overflow: TextOverflow.ellipsis,
//                         style: Theme.of(context)
//                             .textTheme
//                             .bodyMedium
//                             ?.copyWith(fontWeight: FontWeight.bold)),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class PlaylistGridView extends StatelessWidget {
//   final List<Playlist> playlists;
//   final Function(Playlist) onPlaylistTapped;
//   const PlaylistGridView(
//       {super.key, required this.playlists, required this.onPlaylistTapped});

//   @override
//   Widget build(BuildContext context) {
//     return GridView.builder(
//       padding: const EdgeInsets.all(16),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           crossAxisSpacing: 16,
//           mainAxisSpacing: 16,
//           childAspectRatio: 1.0),
//       itemCount: playlists.length,
//       itemBuilder: (context, index) {
//         final playlist = playlists[index];
//         return Card(
//           elevation: 0,
//           margin: EdgeInsets.zero,
//           clipBehavior: Clip.antiAlias,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           child: InkWell(
//             onTap: () => onPlaylistTapped(playlist),
//             child: Stack(
//               fit: StackFit.expand,
//               children: [
//                 if (playlist.thumbnailUrl.isNotEmpty)
//                   Image.network(playlist.thumbnailUrl,
//                       fit: BoxFit.cover,
//                       errorBuilder: (c, e, s) =>
//                           const Center(child: Icon(Icons.broken_image)))
//                 else
//                   Container(
//                       color: Colors.grey,
//                       child: const Icon(Icons.video_library)),
//                 Container(
//                     decoration: BoxDecoration(
//                         gradient: LinearGradient(colors: [
//                   Colors.black.withOpacity(0.7),
//                   Colors.transparent
//                 ], begin: Alignment.bottomCenter, end: Alignment.center))),
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(playlist.title,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 4),
//                       Text('${playlist.itemCount} videos',
//                           style: Theme.of(context)
//                               .textTheme
//                               .bodySmall
//                               ?.copyWith(color: Colors.white70)),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// // --- Video Player Page - CORRECTED FOR youtube_player_flutter ---
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
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);
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

// // --- Reusable Shimmer & Empty State Widgets ---
// class _VideoListShimmer extends StatelessWidget {
//   const _VideoListShimmer();
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Shimmer.fromColors(
//       baseColor: theme.splashColor,
//       highlightColor: theme.cardColor,
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: 8,
//         itemBuilder: (context, index) => Card(
//           elevation: 0,
//           margin: const EdgeInsets.only(bottom: 16),
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           child: Row(children: [
//             Container(width: 140, height: 80, color: Colors.white),
//             Expanded(
//                 child: Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Container(
//                               width: double.infinity,
//                               height: 16,
//                               color: Colors.white),
//                           const SizedBox(height: 8),
//                           Container(
//                               width: 100, height: 16, color: Colors.white),
//                         ]))),
//           ]),
//         ),
//       ),
//     );
//   }
// }

// class _PlaylistGridShimmer extends StatelessWidget {
//   const _PlaylistGridShimmer();
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Shimmer.fromColors(
//       baseColor: theme.splashColor,
//       highlightColor: theme.cardColor,
//       child: GridView.builder(
//         padding: const EdgeInsets.all(16),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             crossAxisSpacing: 16,
//             mainAxisSpacing: 16,
//             childAspectRatio: 1.0),
//         itemCount: 6,
//         itemBuilder: (context, index) => Card(
//             elevation: 0,
//             margin: EdgeInsets.zero,
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             child: Container(color: Colors.white)),
//       ),
//     );
//   }
// }

// class _EmptyState extends StatelessWidget {
//   final IconData icon;
//   final String message;
//   final String description;
//   const _EmptyState(
//       {required this.icon, required this.message, required this.description});
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32.0),
//         child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//           Icon(icon, size: 80, color: theme.hintColor.withOpacity(0.5)),
//           const SizedBox(height: 16),
//           Text(message,
//               style: theme.textTheme.titleLarge
//                   ?.copyWith(fontWeight: FontWeight.bold)),
//           const SizedBox(height: 8),
//           Text(description,
//               textAlign: TextAlign.center,
//               style:
//                   theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
//         ]),
//       ),
//     );
//   }
// }