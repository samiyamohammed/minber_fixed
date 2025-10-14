// lib/screens/on_demand_page.dart (Fully Updated & Ready to Paste)

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class OnDemandPage extends StatefulWidget {
  const OnDemandPage({super.key});

  @override
  State<OnDemandPage> createState() => _OnDemandPageState();
}

class _OnDemandPageState extends State<OnDemandPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategory = 0;
  int _selectedIndex = 1; // For BottomNavBar

  // --- MOCK DATA (Unchanged) ---
  final List<Map<String, dynamic>> _continueWatching = [
    {
      'title': 'A Journey Through Time',
      'description': 'An epic tale of discovery and adventure',
      'progress': 0.7,
      'thumbnail': 'https://picsum.photos/300/169?random=101'
    },
    {
      'title': 'Dinner',
      'description': 'Culinary adventures around the world',
      'progress': 0.4,
      'thumbnail': 'https://picsum.photos/300/169?random=102'
    }
  ];
  final List<Map<String, dynamic>> _downloaded = [
    {
      'title': 'The Silent Hunter',
      'description': 'Top-rated action thriller of the year',
      'thumbnail': 'https://picsum.photos/300/169?random=105',
      'size': '1.2GB'
    },
    {
      'title': 'Wild Wonders: Amazon',
      'description': 'Explore the hidden gems of the rainforest',
      'thumbnail': 'https://picsum.photos/300/169?random=106',
      'size': '2.1GB'
    }
  ];
  final List<Map<String, dynamic>> _trendingVideos = [
    {
      'title': 'The Lost Expedition',
      'description': 'A team of engineers embark on a perfect mission',
      'thumbnail': 'https://picsum.photos/300/169?random=108',
      'views': '15K views'
    },
    {
      'title': 'Echoes of the Past',
      'description': 'Unraveling ancient species in a modern world',
      'thumbnail': 'https://picsum.photos/300/169?random=109',
      'views': '23K views'
    }
  ];

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
    if (routeName.isNotEmpty)
      Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // ✅ UI/UX UPDATE: Using CustomScrollView with Slivers for a more advanced layout
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text("On Demand"),
            floating: true, // App bar appears as you scroll down
            snap: true,
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () {})
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildSearchBar(theme),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              _buildSectionHeader("Continue Watching", "See All", theme),
              const SizedBox(height: 12),
              _buildContinueWatchingList(),
              const SizedBox(height: 24),
              _buildSectionHeader("My Downloads", "See All", theme),
              const SizedBox(height: 12),
              _buildDownloadedList(theme),
              const SizedBox(height: 24),
              _buildSectionHeader("Trending Now", "", theme),
              const SizedBox(height: 12),
              _buildCategoryChips(theme),
              const SizedBox(height: 16),
              _buildTrendingGrid(),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildSearchBar(ThemeData theme) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: "Search movies, series, shows...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          if (action.isNotEmpty)
            TextButton(onPressed: () {}, child: Text(action)),
        ],
      ),
    );
  }

  Widget _buildContinueWatchingList() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _continueWatching.length,
        itemBuilder: (context, index) =>
            _ContinueWatchingCard(item: _continueWatching[index]),
      ),
    );
  }

  Widget _buildDownloadedList(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _downloaded.length,
      itemBuilder: (context, index) =>
          _DownloadedCard(item: _downloaded[index]),
    );
  }

  Widget _buildCategoryChips(ThemeData theme) {
    final categories = ["All", "Movies", "Series", "Documentaries"];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ChoiceChip(
            label: Text(categories[index]),
            selected: _selectedCategory == index,
            onSelected: (isSelected) {
              if (isSelected) setState(() => _selectedCategory = index);
            },
            backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.6),
            selectedColor: theme.colorScheme.primaryContainer,
            labelStyle: TextStyle(
                fontWeight: _selectedCategory == index
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: theme.colorScheme.onSurface),
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  Widget _buildTrendingGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _trendingVideos.length,
      itemBuilder: (context, index) =>
          _TrendingCard(item: _trendingVideos[index]),
    );
  }

  BottomNavigationBar _buildBottomNavBar(ThemeData theme) {
    return BottomNavigationBar(
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
            label: "Chat Bot"),
        BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.apps),
            label: "Sub Apps"),
      ],
    );
  }
}

// --- REUSABLE CARD WIDGETS ---

class _ContinueWatchingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ContinueWatchingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 280,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    item['thumbnail'],
                    fit: BoxFit.cover,
                    // ✅ UI/UX UPDATE: Shimmer loading for image
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Shimmer.fromColors(
                        baseColor: theme.splashColor,
                        highlightColor: theme.cardColor,
                        child: Container(color: Colors.white),
                      );
                    },
                  ),
                ),
                // Play button overlay
                Container(
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 40),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'],
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(item['description'],
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Spacer(),
            LinearProgressIndicator(
              value: item['progress'],
              backgroundColor: theme.dividerColor,
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadedCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _DownloadedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 70,
            child: Image.network(item['thumbnail'], fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'],
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(item['size'],
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                ],
              ),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _TrendingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Image.network(item['thumbnail'], fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'],
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Text(item['views'],
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
