// lib/screens/media/media_hub_screen.dart
import 'package:flutter/material.dart';
import '../../models/channel_model.dart';
import '../../services/media_api_service.dart';
import '../../widgets/media/empty_state_widget.dart';
import './channel_detail_screen.dart';

class MediaHubScreen extends StatefulWidget {
  const MediaHubScreen({super.key});

  @override
  State<MediaHubScreen> createState() => _MediaHubScreenState();
}

class _MediaHubScreenState extends State<MediaHubScreen> {
  int _selectedIndex = 1;
  final MediaApiService _apiService = MediaApiService();
  List<Channel>? _channels;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Load from cache first for instant UI
    if (_channels == null) {
      // Only show shimmer on first-ever load
      final cachedChannels = await _apiService.getChannels(fromCache: true);
      if (mounted) {
        setState(() {
          _channels = cachedChannels;
        });
      }
    }

    // 2. Then, fetch from network to get the latest data
    try {
      final networkChannels = await _apiService.getChannels();
      if (mounted) {
        setState(() {
          _channels = networkChannels;
          _error = null;
        });
      }
    } catch (e) {
      print("Failed to fetch network channels: $e");
      if (mounted && (_channels == null || _channels!.isEmpty)) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    String routeName = '';
    switch (index) {
      case 0:
        routeName = '/home';
        break;
      case 1:
        break;
      case 2:
        routeName = '/prayer';
        break;
      case 3:
        routeName = '/chatbot';
        break;
      case 4:
        routeName = '/subapps';
        break;
    }
    if (routeName.isNotEmpty) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Hub'),
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.unselectedWidgetColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.tv_outlined),
              activeIcon: Icon(Icons.tv),
              label: "Media"),
          BottomNavigationBarItem(
              icon: Icon(Icons.mosque_outlined),
              activeIcon: Icon(Icons.mosque),
              label: "Prayer"),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: "ChatBot"),
          BottomNavigationBarItem(
              icon: Icon(Icons.apps_outlined),
              activeIcon: Icon(Icons.apps),
              label: "Sub Apps"),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_channels == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        message: "Failed to Load",
        description: "Please check your connection and pull to refresh.",
      );
    }
    if (_channels!.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.tv_off_outlined,
        message: "No Channels Found",
        description: "There are currently no channels available.",
      );
    }

    final channels = _channels!;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChannelDetailScreen(channel: channel),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        channel.thumbnailUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) =>
                            const Icon(Icons.tv, size: 60),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        channel.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
