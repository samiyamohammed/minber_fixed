import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class LiveStreamPage extends StatefulWidget {
  const LiveStreamPage({super.key});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  late VlcPlayerController _controller;
  bool _isBuffering = true;
  bool _hasError = false;
  bool _isMuted = false;
  bool _isFullScreen = false;
  Timer? _retryTimer;

  final String streamUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _controller = VlcPlayerController.network(
      streamUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(1500),
        ]),
        http: VlcHttpOptions([
          VlcHttpOptions.httpReconnect(true),
        ]),
        rtp: VlcRtpOptions([
          VlcRtpOptions.rtpOverRtsp(true),
        ]),
      ),
    );

    _controller.addListener(() {
      final state = _controller.value;
      if (state.isBuffering != _isBuffering) {
        setState(() => _isBuffering = state.isBuffering);
      }

      if (state.hasError && !_hasError) {
        setState(() => _hasError = true);
        _scheduleReconnect();
      }
    });
  }

  void _scheduleReconnect() {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 5), () async {
      if (!mounted) return;
      setState(() => _hasError = false);
      await _controller.stop();
      await _controller.setMediaFromNetwork(streamUrl, autoPlay: true);
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _controller.stop();
    _controller.dispose();
    _exitFullScreen();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 100);
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      // Go full-screen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Exit full-screen
      _exitFullScreen();
    }
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final player = Stack(
      alignment: Alignment.center,
      children: [
        VlcPlayer(
          controller: _controller,
          aspectRatio: 16 / 9,
          placeholder: const Center(
              child: CircularProgressIndicator(color: Colors.white)),
        ),
        if (_isBuffering)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        if (_hasError)
          const Center(
            child: Text(
              'Reconnecting...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _toggleMute,
              ),
              IconButton(
                icon: Icon(
                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: _toggleFullScreen,
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: const Text('Live Stream'),
              backgroundColor: Colors.black,
            ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: player,
        ),
      ),
    );
  }
}
