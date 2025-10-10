// lib/screens/live_stream_page.dart (Fully Updated & Corrected)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class LiveStreamPage extends StatefulWidget {
  const LiveStreamPage({super.key});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  Timer? _bufferingTimer;
  bool _isConnecting = true;
  bool _isStuckBuffering = false;

  final String streamUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

  @override
  void initState() {
    super.initState();
    // ✅ CORRECTION: Removed forced landscape orientation on page load
    initializePlayer();
  }

  @override
  void dispose() {
    // ✅ CORRECTION: Reset orientation to be safe when leaving the page
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _bufferingTimer?.cancel();
    _videoPlayerController.removeListener(_videoListener);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> initializePlayer() async {
    if (mounted)
      setState(() {
        _isConnecting = true;
        _isStuckBuffering = false;
      });
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(streamUrl));
    _videoPlayerController.addListener(_videoListener);

    try {
      await _videoPlayerController.initialize();
      _createChewieController();
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _createChewieController() {
    final theme = Theme.of(context);

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      isLive: true,

      // ✅ CORRECTION: Set fullScreenByDefault to false
      fullScreenByDefault: false,

      // ✅ CORRECTION: Added this to handle orientation automatically
      deviceOrientationsAfterFullScreen: const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
      // This tells Chewie to return to portrait when exiting full screen.
      // It will automatically handle going to landscape when entering full screen.

      allowedScreenSleep: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: theme.colorScheme.primary,
        handleColor: theme.colorScheme.primary,
        bufferedColor: theme.colorScheme.onSurface.withOpacity(0.5),
        backgroundColor: theme.colorScheme.onSurface.withOpacity(0.2),
      ),
      placeholder: Container(color: Colors.black),
      autoInitialize: true,
    );
  }

  void _videoListener() {
    if (!mounted || !_videoPlayerController.value.isInitialized) return;
    if (_videoPlayerController.value.isBuffering) {
      _bufferingTimer ??= Timer(const Duration(seconds: 15), () {
        if (_videoPlayerController.value.isBuffering && mounted) {
          setState(() => _isStuckBuffering = true);
          _restartStream();
        }
      });
    } else {
      _bufferingTimer?.cancel();
      _bufferingTimer = null;
      if (_isStuckBuffering && mounted) {
        setState(() => _isStuckBuffering = false);
      }
    }
  }

  Future<void> _restartStream() async {
    if (!mounted) return;
    _videoPlayerController.removeListener(_videoListener);
    await _videoPlayerController.dispose();
    await initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECTION: The page is now built in a standard Scaffold
    return Scaffold(
      appBar: AppBar(title: const Text("Live Stream")),
      body: _buildPlayer(),
    );
  }

  Widget _buildPlayer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                if (_chewieController != null &&
                    _chewieController!
                        .videoPlayerController.value.isInitialized)
                  Chewie(controller: _chewieController!)
                else
                  _buildStatusIndicator(
                    logoAsset: 'assets/images/minber.jpg',
                    message: "Connecting to Live Stream...",
                  ),
                _buildStuckBufferingOverlay(),
              ],
            ),
          ),
        ),
        // You can add other widgets below the player here, for example:
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Minber TV - Live Broadcast",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                  "You are watching the official live stream. Share with your friends and family.",
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(
      {required String logoAsset, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(logoAsset, width: 60, height: 60),
          const SizedBox(height: 20),
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: Colors.white)),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStuckBufferingOverlay() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _isStuckBuffering ? 1.0 : 0.0,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: _buildStatusIndicator(
          logoAsset: 'assets/images/logo.png',
          message: "Reconnecting...",
        ),
      ),
    );
  }
}
