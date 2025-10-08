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
    // Force landscape orientation when the page loads
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    if (mounted) {
      setState(() {
        _isConnecting = true;
        _isStuckBuffering = false;
      });
    }

    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(streamUrl));
    _videoPlayerController.addListener(_videoListener);

    try {
      await _videoPlayerController.initialize();
      _createChewieController();
    } catch (e) {
      print("Error initializing video player: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      isLive: true,

      // --- FIX: THIS SYNCS THE UI WITH THE FORCED LANDSCAPE ORIENTATION ---
      fullScreenByDefault: true,

      // --- BEST PRACTICE: PREVENT SCREEN FROM SLEEPING ---
      allowedScreenSleep: false,

      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        handleColor: Colors.red,
        bufferedColor: Colors.white70,
        backgroundColor: Colors.white24,
      ),
      placeholder: Container(
        color: Colors.black,
      ),
      autoInitialize: true,
    );
  }

  void _videoListener() {
    if (!mounted || !_videoPlayerController.value.isInitialized) return;

    if (_videoPlayerController.value.isBuffering) {
      _bufferingTimer ??= Timer(const Duration(seconds: 15), () {
        if (_videoPlayerController.value.isBuffering && mounted) {
          print("Stuck buffering, attempting to restart stream...");
          if (mounted) {
            setState(() {
              _isStuckBuffering = true;
            });
          }
          _restartStream();
        }
      });
    } else {
      _bufferingTimer?.cancel();
      _bufferingTimer = null;
      if (_isStuckBuffering) {
        if (mounted) {
          setState(() {
            _isStuckBuffering = false;
          });
        }
      }
    }
  }

  Future<void> _restartStream() async {
    if (!mounted) return;
    print("Restarting stream...");

    _videoPlayerController.removeListener(_videoListener);
    await _videoPlayerController.dispose();

    await initializePlayer();
  }

  @override
  void dispose() {
    // --- IMPORTANT: Reset orientation to portrait when leaving the page ---
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _bufferingTimer?.cancel();
    _videoPlayerController.removeListener(_videoListener);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildPlayer(),
    );
  }

  Widget _buildPlayer() {
    if (_chewieController == null ||
        !_chewieController!.videoPlayerController.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              _isStuckBuffering
                  ? "Reconnecting to stream..."
                  : "Connecting to live stream...",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: Chewie(
            controller: _chewieController!,
          ),
        ),

        // Custom Back Button on top of the player
        Positioned(
          top: 16.0,
          left: 16.0,
          child: SafeArea(
            child: IconButton(
              icon:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 28.0),
              style: IconButton.styleFrom(backgroundColor: Colors.black45),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
          ),
        ),
      ],
    );
  }
}
