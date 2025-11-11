// lib/screens/live_screen.dart (Final Version - No Overflow Menu)

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LiveStreamPage extends StatefulWidget {
  const LiveStreamPage({super.key});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  late BetterPlayerController _betterPlayerController;
  final String streamUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

  @override
  void initState() {
    super.initState();

    // 1. CONFIGURE THE PLAYER
    // ========================

    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      streamUrl,
      liveStream: true,
    );

    BetterPlayerConfiguration betterPlayerConfiguration =
        const BetterPlayerConfiguration(
      fullScreenByDefault: true,
      autoPlay: true,
      allowedScreenSleep: false,
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],

      // ✅ --- THIS IS THE UPDATED CONFIGURATION --- ✅
      // We are telling the controls to completely disable the overflow menu.
      // This will remove the "three dots" icon from the player controls.
      controlsConfiguration: BetterPlayerControlsConfiguration(
        enableOverflowMenu: false,
      ),
    );

    // 2. INITIALIZE THE CONTROLLER
    // =============================
    _betterPlayerController = BetterPlayerController(
      betterPlayerConfiguration,
      betterPlayerDataSource: betterPlayerDataSource,
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            BetterPlayer(
              controller: _betterPlayerController,
            ),
            Positioned(
              top: 40.0,
              left: 16.0,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Go back',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
