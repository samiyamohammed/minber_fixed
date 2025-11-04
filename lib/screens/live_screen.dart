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

    // Data source configuration for the HLS live stream
    BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      streamUrl,
      liveStream: true, // This is crucial for live streams!
    );

    // Main player configuration
    BetterPlayerConfiguration betterPlayerConfiguration =
        const BetterPlayerConfiguration(
      // The magic happens here: start in fullscreen (which will be landscape)
      fullScreenByDefault: true,
      // Automatically play the stream when initialized
      autoPlay: true,
      // Prevent the device from sleeping while the video is playing
      allowedScreenSleep: false,
      // Ensure that when the user exits fullscreen, the app returns to portrait mode
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
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
    // Restore default orientations and dispose of the controller to free resources
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _betterPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use WillPopScope to handle the system back button on Android
    return WillPopScope(
      onWillPop: () async {
        // When the back button is pressed, navigate back.
        // The dispose() method will handle restoring the orientation.
        Navigator.pop(context);
        return true; // Allow the pop to happen
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // Use a Stack to overlay the back button on top of the player
        body: Stack(
          children: [
            // The main video player widget
            BetterPlayer(
              controller: _betterPlayerController,
            ),

            // Custom back button
            Positioned(
              top: 40.0, // Adjust for status bar or notch
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
                      // Navigate back to the previous page
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
