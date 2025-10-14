// lib/live_stream_page.dart
import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LiveStreamPage extends StatefulWidget {
  const LiveStreamPage({super.key});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  // ----- CONFIG -----
  final String _streamUrl =
      'http://msa.merkuz.com:8888/live/stream1/index.m3u8';
  static const Duration _heartbeatInterval = Duration(seconds: 5);
  static const Duration _stallThreshold = Duration(seconds: 10);
  static const Duration _periodicRefreshInterval = Duration(minutes: 10);
  static const int _maxReconnectAttempts = 3;

  // ----- PLAYERS / CONTROLLERS -----
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  // ----- STATE -----
  bool _isLoading = true;
  bool _hasError = false;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;

  // ----- TIMERS & MONITORS -----
  Timer? _heartbeatTimer;
  Timer? _periodicRefreshTimer;

  // Track last known playback position for "stalled" detection
  Duration? _lastPosition;
  DateTime? _lastPositionUpdateTime;

  // Reconnect backoff schedule (seconds)
  final List<int> _backoffSeconds = [2, 5, 10];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
    _startHeartbeat();
    _startPeriodicRefresh();
  }

  // -------------------------
  // Initialization & helpers
  // -------------------------
  Future<void> _initializePlayer() async {
    if (!mounted) return;

    setState(() {
      _hasError = false;
      _isLoading = !_isReconnecting;
    });

    await _cleanUpControllers();

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(_streamUrl),
      );

      await _videoPlayerController!.initialize();

      if (!mounted) return;

      _videoPlayerController!.addListener(_videoListener);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false, // For live streams, looping is typically false
        isLive: true,
        allowFullScreen: true,
        showControlsOnInitialize: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Playback error: $errorMessage',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          );
        },
      );

      _lastPosition = _videoPlayerController!.value.position;
      _lastPositionUpdateTime = DateTime.now();

      setState(() {
        _isLoading = false;
        _isReconnecting = false;
        _reconnectAttempts = 0;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Error initializing player: $e');
      if (mounted) {
        _scheduleReconnect();
      }
    }
  }

  void _videoListener() {
    if (!mounted || _videoPlayerController == null) return;

    final value = _videoPlayerController!.value;

    try {
      final currentPosition = value.position;
      if (_lastPosition == null || currentPosition > _lastPosition!) {
        _lastPosition = currentPosition;
        _lastPositionUpdateTime = DateTime.now();
      }
    } catch (_) {
      // Ignore position comparison errors
    }

    // Check for player errors
    if (value.hasError && !_isReconnecting) {
      debugPrint('Video player reported an error: ${value.errorDescription}');
      _scheduleReconnect(immediate: true);
    }
  }

  // -------------------------
  // Heartbeat & Stall logic
  // -------------------------
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      if (!mounted) return;

      if (_videoPlayerController == null ||
          !_videoPlayerController!.value.isInitialized ||
          _isReconnecting) {
        return;
      }

      final value = _videoPlayerController!.value;

      // Check for prolonged buffering
      if (value.isBuffering) {
        final since = _lastPositionUpdateTime ?? DateTime.now();
        final bufferingDuration = DateTime.now().difference(since);
        if (bufferingDuration >= _stallThreshold) {
          debugPrint(
              'Detected prolonged buffering: $bufferingDuration -> reconnect');
          _scheduleReconnect(immediate: true);
          return;
        }
      }

      // Check for stagnant playback position
      if (_lastPositionUpdateTime != null) {
        final noAdvance = DateTime.now().difference(_lastPositionUpdateTime!);
        if (noAdvance >= _stallThreshold && value.isPlaying) {
          debugPrint('Playback position stagnant for $noAdvance -> reconnect');
          _scheduleReconnect(immediate: true);
          return;
        }
      }

      // Check if playback stopped unexpectedly
      if (!value.isPlaying && !value.isBuffering && value.isInitialized) {
        debugPrint('Playback stopped unexpectedly -> reconnect');
        _scheduleReconnect(immediate: true);
        return;
      }
    });
  }

  // -------------------------
  // Periodic refresh
  // -------------------------
  void _startPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(_periodicRefreshInterval, (_) async {
      if (!mounted) return;

      if (_videoPlayerController == null ||
          !_videoPlayerController!.value.isInitialized ||
          _isReconnecting) {
        return;
      }

      final lastUpdate = _lastPositionUpdateTime;
      if (lastUpdate == null) {
        debugPrint(
            'Periodic refresh: lastPositionUpdateTime is null, refreshing.');
        _scheduleReconnect(immediate: true, force: true);
        return;
      }

      final noAdvance = DateTime.now().difference(lastUpdate);
      if (noAdvance >= const Duration(seconds: 30)) {
        debugPrint(
            'Periodic refresh: playback stale ($noAdvance). Triggering reconnect.');
        _scheduleReconnect(immediate: true, force: true);
      }
    });
  }

  // -------------------------
  // Reconnect logic
  // -------------------------
  void _scheduleReconnect({bool immediate = false, bool force = false}) {
    if (!mounted) return;
    if (_isReconnecting && !force) return;

    _attemptReconnect(immediate: immediate);
  }

  Future<void> _attemptReconnect({bool immediate = false}) async {
    if (!mounted) return;
    if (_isReconnecting) return;

    setState(() {
      _isReconnecting = true;
      _isLoading = false;
      _hasError = false;
    });

    while (_reconnectAttempts < _maxReconnectAttempts && mounted) {
      final backoffIndex =
          _reconnectAttempts.clamp(0, _backoffSeconds.length - 1);
      final backoff = _backoffSeconds[backoffIndex];

      if (!immediate && _reconnectAttempts > 0) {
        await Future.delayed(Duration(seconds: backoff));
      } else if (_reconnectAttempts > 0) {
        await Future.delayed(Duration(seconds: backoff));
      }

      _reconnectAttempts++;
      debugPrint(
          'Reconnect attempt #$_reconnectAttempts (backoff ${backoff}s)');

      try {
        await _cleanUpControllers();

        if (!mounted) break;

        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(_streamUrl),
        );

        await _videoPlayerController!.initialize();

        if (!mounted) {
          await _cleanUpControllers();
          break;
        }

        _videoPlayerController!.addListener(_videoListener);

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          isLive: true,
          allowFullScreen: true,
          showControlsOnInitialize: false,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                'Playback error: $errorMessage',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            );
          },
        );

        _lastPosition = _videoPlayerController!.value.position;
        _lastPositionUpdateTime = DateTime.now();

        if (mounted) {
          setState(() {
            _isReconnecting = false;
            _hasError = false;
            _isLoading = false;
            _reconnectAttempts = 0;
          });
        }
        debugPrint('Reconnect successful.');
        return;
      } catch (e) {
        debugPrint('Reconnect attempt #$_reconnectAttempts failed: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isReconnecting = false;
        _hasError = true;
        _isLoading = false;
      });
      debugPrint('All reconnect attempts failed.');
    }
  }

  // -------------------------
  // Cleanup
  // -------------------------
  Future<void> _cleanUpControllers() async {
    try {
      _chewieController?.pause();
    } catch (_) {}

    try {
      if (_videoPlayerController != null) {
        _videoPlayerController!.removeListener(_videoListener);
      }
    } catch (_) {}

    try {
      _chewieController?.dispose();
    } catch (_) {}
    _chewieController = null;

    try {
      await _videoPlayerController?.dispose();
    } catch (_) {}
    _videoPlayerController = null;
  }

  Future<void> _manualRetry() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _isReconnecting = false;
      _reconnectAttempts = 0;
    });

    await _initializePlayer();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _periodicRefreshTimer?.cancel();
    _cleanUpControllers();
    super.dispose();
  }

  // -------------------------
  // UI
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resilient Live Stream'),
      ),
      body: Center(
        child: _buildPlayerWidget(),
      ),
    );
  }

  Widget _buildPlayerWidget() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading stream...'),
        ],
      );
    }

    if (_hasError) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load stream',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Please check your connection and try again.'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _manualRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (_chewieController == null ||
        !_chewieController!.videoPlayerController.value.isInitialized) {
      return const CircularProgressIndicator();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Chewie(controller: _chewieController!),
        if (_isReconnecting)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Reconnecting to stream...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
