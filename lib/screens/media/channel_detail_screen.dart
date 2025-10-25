// lib/screens/media/channel_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/channel_model.dart';
import '../../models/video_model.dart';
import '../../models/playlist_model.dart';
import '../../services/media_api_service.dart';
import '../../widgets/media/video_list_view.dart';
import '../../widgets/media/playlist_grid_view.dart';
import '../../widgets/media/empty_state_widget.dart';
import '../../widgets/media/media_shimmers.dart';

class ChannelDetailScreen extends StatefulWidget {
  final Channel channel;
  const ChannelDetailScreen({super.key, required this.channel});

  @override
  State<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends State<ChannelDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channel.title),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3.0,
          tabs: const [
            Tab(text: "All Videos"),
            Tab(text: "Playlists"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AllVideosTab(channel: widget.channel),
          PlaylistsTab(channel: widget.channel),
        ],
      ),
    );
  }
}

// Internal Tab Widgets
class AllVideosTab extends StatefulWidget {
  final Channel channel;
  const AllVideosTab({super.key, required this.channel});
  @override
  State<AllVideosTab> createState() => _AllVideosTabState();
}

class _AllVideosTabState extends State<AllVideosTab>
    with AutomaticKeepAliveClientMixin {
  final MediaApiService _apiService = MediaApiService();
  List<Video>? _videos;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_videos == null) {
      final cachedData = await _apiService.getAllVideosForChannel(
          channelId: widget.channel.id, fromCache: true);
      if (mounted) setState(() => _videos = cachedData);
    }

    try {
      final networkData = await _apiService.getAllVideosForChannel(
          channelId: widget.channel.id);
      if (mounted)
        setState(() {
          _videos = networkData;
          _error = null;
        });
    } catch (e) {
      print("Failed to fetch network videos: $e");
      if (mounted && (_videos == null || _videos!.isEmpty)) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_videos == null && _error == null) return const VideoListShimmer();
    if (_error != null)
      return const EmptyStateWidget(
          icon: Icons.error_outline,
          message: "An Error Occurred",
          description: "Could not load videos. Please pull to refresh.");
    if (_videos!.isEmpty)
      return const EmptyStateWidget(
        icon: Icons.videocam_off_outlined,
        message: "No Videos Found",
        description:
            "There are currently no videos available for this channel.",
      );
    return RefreshIndicator(
        onRefresh: _loadData, child: VideoListView(videos: _videos!));
  }

  @override
  bool get wantKeepAlive => true;
}

class PlaylistsTab extends StatefulWidget {
  final Channel channel;
  const PlaylistsTab({super.key, required this.channel});
  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab>
    with AutomaticKeepAliveClientMixin {
  final MediaApiService _apiService = MediaApiService();
  List<dynamic>? _data;
  Playlist? _selectedPlaylist;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _selectedPlaylist = null;
      _error = null;
    });

    if (_data == null) {
      final cachedData = await _apiService.getPlaylists(
          channelId: widget.channel.id, fromCache: true);
      if (mounted) setState(() => _data = cachedData);
    }

    try {
      final networkData =
          await _apiService.getPlaylists(channelId: widget.channel.id);
      if (mounted)
        setState(() {
          _data = networkData;
          _error = null;
        });
    } catch (e) {
      print("Failed to fetch network playlists: $e");
      if (mounted && (_data == null || _data!.isEmpty)) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _onPlaylistTapped(Playlist playlist) async {
    setState(() {
      _selectedPlaylist = playlist;
      _data = null; // Show loading shimmer for videos
    });

    try {
      final videos =
          await _apiService.getVideosForPlaylist(playlistId: playlist.id);
      if (mounted) setState(() => _data = videos);
    } catch (e) {
      print("Failed to fetch playlist videos: $e");
      if (mounted) setState(() => _data = []); // Show empty state on error
    }
  }

  void _backToPlaylists() {
    _loadPlaylists();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final bool isPlaylistView = _selectedPlaylist == null;

    if (_data == null && _error == null) {
      return isPlaylistView
          ? const PlaylistGridShimmer()
          : const VideoListShimmer();
    }
    if (_error != null) {
      return const EmptyStateWidget(
          icon: Icons.error_outline,
          message: "An Error Occurred",
          description: "Could not load content. Please try again.");
    }
    if (_data!.isEmpty) {
      return EmptyStateWidget(
        icon: isPlaylistView
            ? Icons.playlist_remove_rounded
            : Icons.videocam_off_outlined,
        message: isPlaylistView ? "No Playlists Found" : "No Videos Found",
        description: isPlaylistView
            ? "There are no playlists available right now."
            : "This playlist is currently empty.",
      );
    }

    if (isPlaylistView) {
      final playlists = _data!.cast<Playlist>();
      return RefreshIndicator(
          onRefresh: _loadPlaylists,
          child: PlaylistGridView(
              playlists: playlists, onPlaylistTapped: _onPlaylistTapped));
    } else {
      final videos = _data!.cast<Video>();
      return VideoListView(videos: videos);
    }
  }

  @override
  bool get wantKeepAlive => true;
}
