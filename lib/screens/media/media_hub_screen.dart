// lib/screens/media/media_hub_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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

  // --- START: NEW ROBUST SORTING LOGIC ---
  List<Channel> _sortChannels(List<Channel> channels) {
    // This list now contains the prefixes of the channel titles.
    // The casing and spelling must match the beginning of the titles from your API.
    const customOrderPrefixes = [
      'Minber TV',
      'Minber News',
      'Minber AL Elm', // Matching the casing from your screenshot
      'Minber Records',
    ];

    channels.sort((a, b) {
      // Find the index in our custom list where the channel title starts with a prefix.
      int indexA = customOrderPrefixes
          .indexWhere((prefix) => a.title.startsWith(prefix));
      int indexB = customOrderPrefixes
          .indexWhere((prefix) => b.title.startsWith(prefix));

      // If a channel isn't found in our list, move it to the end.
      if (indexA == -1) return 1;
      if (indexB == -1) return -1;

      // Sort based on the order in our custom list.
      return indexA.compareTo(indexB);
    });

    return channels;
  }
  // --- END: NEW ROBUST SORTING LOGIC ---

  Future<void> _loadData() async {
    if (mounted) setState(() => _error = null);

    // Load from cache first for an instant UI
    if (_channels == null) {
      final cachedChannels = await _apiService.getChannels(fromCache: true);
      if (mounted && cachedChannels.isNotEmpty) {
        setState(() {
          _channels = _sortChannels(cachedChannels);
        });
      }
    }

    // Then, fetch from the network to get the latest data
    try {
      final networkChannels = await _apiService.getChannels();
      if (mounted) {
        setState(() {
          _channels = _sortChannels(networkChannels);
        });
      }
    } catch (e) {
      if (mounted && (_channels == null || _channels!.isEmpty)) {
        setState(() => _error = e.toString());
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
      // REPLACE IT WITH THIS:

      appBar: AppBar(
        title: const Text('Media Hub'),
        centerTitle: true,
        backgroundColor:
            Colors.transparent, // Makes the app bar background see-through
        elevation: 0, // Removes the shadow line
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(),
      ),
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
      return _buildShimmerList();
    }
    if (_error != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        message: "Failed to Load",
        description: "Please check your connection and pull to refresh.",
        onRefresh: _loadData,
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return _AnimatedListItem(
          index: index,
          child: _buildChannelCard(channel),
        );
      },
    );
  }

  // --- THIS IS THE CORRECT, COMPACT UI ---
  Widget _buildChannelCard(Channel channel) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChannelDetailScreen(channel: channel))),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  channel.thumbnailUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.tv, size: 30, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  channel.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.0)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Animation Widget ---
class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedListItem({required this.index, required this.child});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.index * 75), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
