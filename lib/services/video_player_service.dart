// lib/services/video_player_service.dart

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';

class VideoPlayerService {
  // A static, single instance of the controller
  static BetterPlayerController? _bannerPlayerController;

  static const String streamUrl =
      'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

  static BetterPlayerController getBannerPlayerController() {
    // If the controller doesn't exist yet, create it.
    _bannerPlayerController ??= _createBannerPlayerController();
    return _bannerPlayerController!;
  }

  static BetterPlayerController _createBannerPlayerController() {
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      streamUrl,
      liveStream: true,
      notificationConfiguration:
          const BetterPlayerNotificationConfiguration(showNotification: false),
    );

    final controller = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        looping: true,
        // We will control the fit from the UI, so this is less critical now
        fit: BoxFit.contain,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
        ),
        // Let's also disable the player's internal lifecycle handling
        // so we can manage it manually and reliably.
        handleLifecycle: false,
      ),
      betterPlayerDataSource: dataSource,
    );

    controller.setVolume(0.0); // Start muted by default
    return controller;
  }

  // A method to dispose of the controller when the app truly closes
  static void dispose() {
    _bannerPlayerController?.dispose();
    _bannerPlayerController = null;
  }
}
