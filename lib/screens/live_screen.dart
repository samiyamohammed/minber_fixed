import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // <<< Required Import
import '../core/app_colors.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  // Video Stream URL (HLS link)
  final String _hlsUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';

  // Video Controller
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Initial chat messages
  final List<Map<String, String>> _chatMessages = [
    {
      'name': 'Aisha',
      'message': 'Salam everyone! So excited for this stream!',
      'time': '2 min ago',
    },
    {
      'name': 'Ahmed',
      'message': 'Waaialkumadami Great to be here.',
      'time': '1 min ago',
    },
    {
      'name': 'Fatima',
      'message': 'The speaker is excellent, learning so much!',
      'time': 'Just now',
    },
  ];

  @override
  void initState() {
    super.initState();

    // --- Video Player Initialization (Same logic as YoutubePlayerPage) ---
    _videoController = VideoPlayerController.networkUrl(Uri.parse(_hlsUrl))
      ..initialize()
          .then((_) {
            // Only set state if the widget is still mounted
            if (mounted) {
              setState(() {
                _videoInitialized = true;
              });
              // Start playing the video automatically
              _videoController.play();
            }
          })
          .catchError((error) {
            debugPrint("Video initialization error: $error");
            if (mounted) {
              setState(() {
                _videoInitialized = false; // Mark as failed
              });
              // Show a toast message for better user feedback
              // NOTE: You'll need to add fluttertoast dependency for this
              // Fluttertoast.showToast(msg: "Failed to load stream.", backgroundColor: Colors.red);
            }
          });
    _videoController.setLooping(true); // Loop the video indefinitely
    // ---------------------------------------------------------------------
  }

  @override
  void dispose() {
    // --- Dispose the controller (Same logic as YoutubePlayerPage's dispose) ---
    _videoController.dispose();
    // If you add a VideoPlayer widget, you dispose the controller with dispose(), not close()
    // _controller.close(); // Only for youtube_player_flutter
    // --------------------------------------------------------------------------

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Helper to determine chat avatar color
  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.primary,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    final index = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        _chatMessages.insert(0, {
          'name': 'You',
          'message': _messageController.text,
          'time': 'Just now',
        });
        _messageController.clear();
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // Video Player Widget Builder (Now with basic controls)
  Widget _buildVideoPlayerBanner(ThemeData theme, Size size) {
    // Determine status of the video player
    Widget videoContent;
    if (_videoInitialized && _videoController.value.isInitialized) {
      // Show the video and stack controls on top
      videoContent = Stack(
        alignment: Alignment.center,
        children: [
          // AspectRatio is key for fitting the video correctly
          AspectRatio(
            aspectRatio: _videoController.value.aspectRatio,
            child: VideoPlayer(_videoController),
          ),

          // Custom controls can be added here, e.g., a simple play/pause button
          GestureDetector(
            onTap: () {
              setState(() {
                _videoController.value.isPlaying
                    ? _videoController.pause()
                    : _videoController.play();
              });
            },
            child: AnimatedOpacity(
              opacity: _videoController.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black38,
                child: Center(
                  child: Icon(
                    _videoController.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 50.0,
                  ),
                ),
              ),
            ),
          ),

          // ⚠️ Live Indicator
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "LIVE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // Other overlays (Time, Viewers, etc.)
          // ... (You can add the other Positioned widgets from your original code here)
        ],
      );
    } else if (!_videoInitialized && _videoController.value.hasError) {
      // Error State
      videoContent = const Center(
        child: Text(
          "Error loading stream.",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      // Loading State
      videoContent = const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

    return Container(
      width: size.width,
      height: size.height * 0.25,
      margin: EdgeInsets.symmetric(horizontal: size.width * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.dividerColor.withOpacity(0.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: videoContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Live TV"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: theme.iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🔎 Search Bar
              Padding(
                padding: EdgeInsets.all(size.width * 0.04),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search shows...",
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.iconTheme.color,
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                      vertical: size.height * 0.015,
                    ),
                  ),
                ),
              ),

              // 📺 Tabs
              Container(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTab(size, "Live TV", true, theme),
                    SizedBox(width: size.width * 0.03),
                    _buildTab(size, "On Demand", false, theme),
                    SizedBox(width: size.width * 0.03),
                    _buildTab(size, "YouTube", false, theme),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.02),

              // 🖼️ Live Stream Player
              _buildVideoPlayerBanner(
                theme,
                size,
              ), // <<< Video Player Integration

              SizedBox(height: size.height * 0.02),

              // 💬 Chat Section
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Live Chat",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${_chatMessages.length} messages",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),

                  // Chat List
                  Container(
                    // Removed NeverScrollableScrollPhysics to allow chat scrolling below the video
                    constraints: BoxConstraints(maxHeight: size.height * 0.4),
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      shrinkWrap: true,
                      physics:
                          const ClampingScrollPhysics(), // Can scroll independently
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                      ),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final message = _chatMessages[index];
                        final firstName = message['name']!;
                        final initial = firstName[0];

                        return Container(
                          margin: EdgeInsets.only(bottom: size.height * 0.01),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: size.width * 0.05,
                                backgroundColor: _getAvatarColor(firstName),
                                child: Text(
                                  initial,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: size.width * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          message['name']!,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        SizedBox(width: size.width * 0.02),
                                        Text(
                                          message['time']!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme.hintColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: size.height * 0.005),
                                    Text(
                                      message['message']!,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Input stays pinned
                  Container(
                    padding: EdgeInsets.all(size.width * 0.04),
                    color: theme.cardColor,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: size.width * 0.05,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            "Y",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * 0.03),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: "Say something...",
                              filled: true,
                              fillColor: theme.dividerColor.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.04,
                                vertical: size.height * 0.015,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * 0.03),
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: IconButton(
                            icon: Icon(Icons.send, color: theme.cardColor),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(Size size, String text, bool selected, ThemeData theme) {
    return Expanded(
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          backgroundColor: selected
              ? AppColors.primary
              : theme.dividerColor.withOpacity(0.2),
          padding: EdgeInsets.symmetric(vertical: size.height * 0.015),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : theme.textTheme.bodyMedium?.color,
            fontSize: size.width * 0.04,
          ),
        ),
      ),
    );
  }
}
