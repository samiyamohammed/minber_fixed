// lib/screens/video_player_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart';
import '../services/media_api_service.dart';

import 'media/video_player_web_stub.dart'
    if (dart.library.html) 'media/video_player_web.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final Video? initialVideo;
  final List<Video>? videoList;
  final int? initialIndex;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    this.initialVideo,
    this.videoList,
    this.initialIndex,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;
  final MediaApiService _apiService = MediaApiService();
  Video? _currentVideoDetails;
  int _currentVideoIndex = 0;
  List<Video> _allVideos = [];
  String _currentVideoId = '';

  @override
  void initState() {
    super.initState();
    _currentVideoId = widget.videoId;
    _currentVideoDetails = widget.initialVideo;
    _initializeVideoData();

    if (!kIsWeb) {
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          disableDragSeek: false,
          loop: false,
          enableCaption: true,
          useHybridComposition: false,
          forceHD: true,
        ),
      )..addListener(_playerListener);
    }
  }

  // Listener to get video details once the player is ready
  void _playerListener() {
    if (!kIsWeb &&
        mounted &&
        _controller!.value.isReady &&
        _currentVideoDetails?.title == null &&
        _controller!.metadata.title.isNotEmpty) {
      setState(() {
        _currentVideoDetails = Video(
          id: _controller!.metadata.videoId,
          videoId: _controller!.metadata.videoId,
          title: _controller!.metadata.title,
          thumbnailUrl: YoutubePlayer.getThumbnail(
              videoId: _controller!.metadata.videoId),
          publishedAt: DateTime.now(),
          privacyStatus: '',
        );
      });
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && _controller != null) {
      _controller!.removeListener(_playerListener);
      _controller!.dispose();
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  void _initializeVideoData() {
    if (widget.videoList != null && widget.videoList!.isNotEmpty) {
      _allVideos = widget.videoList!;
      _currentVideoIndex = widget.initialIndex ??
          _allVideos.indexWhere((video) => video.videoId == widget.videoId);
      if (_currentVideoIndex < 0) _currentVideoIndex = 0;
    } else {
      // Fallback if no list is passed - fetches all videos from a default channel
      _apiService
          .getAllVideosForChannel(channelId: 'UCQQWZ1IeswjheSTSEXKcQsA')
          .then((videos) {
        if (mounted) {
          setState(() {
            _allVideos = videos;
            _currentVideoIndex =
                _allVideos.indexWhere((v) => v.videoId == widget.videoId);
            if (_currentVideoIndex == -1) _currentVideoIndex = 0;
          });
        }
      });
    }
  }

  void _playNextVideo() {
    if (!mounted || _allVideos.isEmpty) return;
    int nextIndex = (_currentVideoIndex + 1) % _allVideos.length;
    _playVideoAtIndex(nextIndex);
  }

  void _playVideoAtIndex(int index) {
    if (!mounted || index < 0 || index >= _allVideos.length) return;
    final video = _allVideos[index];
    setState(() {
      _currentVideoIndex = index;
      _currentVideoDetails = video;
      _currentVideoId = video.videoId;
      if (!kIsWeb && _controller != null) {
        _controller!.load(video.videoId);
        _controller!.play();
      }
    });
  }

  Widget _buildVideoPlayer(BuildContext context) {
    if (kIsWeb) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: buildYouTubeIframe(_currentVideoId),
      );
    }
    return YoutubePlayer(
      controller: _controller!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Theme.of(context).colorScheme.primary,
      onEnded: (metaData) {
        _playNextVideo();
      },
    );
  }

  Widget _buildBody(BuildContext context, {Widget? playerOverride}) {
    final player = playerOverride ?? _buildVideoPlayer(context);
    return SafeArea(
      child: Column(
        children: [
          player,
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _currentVideoDetails?.title ??
                          (kIsWeb ? "Now Playing" : "Loading Video Title..."),
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
                        if (_allVideos.isNotEmpty)
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _RelatedVideosList(
                    allVideos: _allVideos,
                    onVideoTap: (video) => _playVideoAtIndex(_allVideos
                        .indexWhere((v) => v.videoId == video.videoId)),
                    currentVideoId:
                        kIsWeb ? _currentVideoId : _currentVideoDetails?.videoId,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Now Playing'),
        ),
        body: _buildBody(context),
      );
    }

    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // Ensure the system overlays are restored correctly
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Theme.of(context).colorScheme.primary,
        onEnded: (metaData) {
          _playNextVideo();
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            centerTitle: true,
            title: const Text('Now Playing'),
          ),
          body: _buildBody(context, playerOverride: player),
        );
      },
    );
  }
}

// --- Helper Widgets ---

class _RelatedVideosList extends StatelessWidget {
  final List<Video> allVideos;
  final Function(Video)? onVideoTap;
  final String? currentVideoId;

  const _RelatedVideosList({
    required this.allVideos,
    this.onVideoTap,
    this.currentVideoId,
  });

  @override
  Widget build(BuildContext context) {
    if (allVideos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(
            3,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _ShimmerVideoCard(),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: allVideos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final video = allVideos[index];
        final isCurrentVideo = video.videoId == currentVideoId;
        return _VideoCard(
          video: video,
          isPlaying: isCurrentVideo,
          onTap: () => onVideoTap?.call(video),
        );
      },
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Video video;
  final bool isPlaying;
  final VoidCallback? onTap;

  const _VideoCard({required this.video, this.isPlaying = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPlaying
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 2)
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
                      fit: BoxFit.cover),
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
                          child: Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 24),
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
                          height: 1.3),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
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
  const _ShimmerVideoCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 70,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white),
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
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 16,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white),
                    ),
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
