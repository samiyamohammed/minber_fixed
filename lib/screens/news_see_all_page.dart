// lib/screens/news_see_all_page.dart
import 'package:flutter/material.dart';
import '../widgets/embedded_web_screen.dart';

class NewsSeeAllPage extends StatefulWidget {
  final List<dynamic> newsArticles;
  final String apiBaseUrl;

  const NewsSeeAllPage({
    super.key,
    required this.newsArticles,
    required this.apiBaseUrl,
  });

  @override
  State<NewsSeeAllPage> createState() => _NewsSeeAllPageState();
}

// Add SingleTickerProviderStateMixin for the TabController
class _NewsSeeAllPageState extends State<NewsSeeAllPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<dynamic> _articleNews;
  late List<dynamic> _videoNews;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with 3 tabs
    _tabController = TabController(length: 3, vsync: this);

    // Filter the articles into separate lists
    _videoNews = widget.newsArticles
        .where((article) =>
            (article['newsUrl'] as String?)?.contains('youtube.com') ?? false)
        .toList();

    _articleNews = widget.newsArticles
        .where((article) =>
            !(article['newsUrl'] as String?)!.contains('youtube.com') ?? true)
        .toList();
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is removed
    _tabController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}y ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}mo ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return ''; // Return empty string if date is invalid
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latest News'),
        // Add the TabBar to the bottom of the AppBar
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Articles'),
            Tab(text: 'Video News'),
          ],
        ),
      ),
      // Use TabBarView to show content based on the selected tab
      body: TabBarView(
        controller: _tabController,
        children: [
          // "All" Tab
          _buildNewsList(widget.newsArticles),
          // "Articles" Tab
          _buildNewsList(_articleNews),
          // "Video News" Tab
          _buildNewsList(_videoNews),
        ],
      ),
    );
  }

  // A reusable widget to build the list for each tab
  Widget _buildNewsList(List<dynamic> articles) {
    if (articles.isEmpty) {
      return const Center(
        child: Text(
          'No items in this category.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        // In a real app, you might re-fetch data here.
        // For now, this is just a placeholder.
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return _buildNewsListItem(context, article);
        },
      ),
    );
  }

  Widget _buildNewsListItem(BuildContext context, dynamic article) {
    final theme = Theme.of(context);
    final headline = article['headline'] ?? 'No Title';
    final newsUrl = article['newsUrl'] as String?;
    String thumbnailUrl = article['thumbnail'] ?? '';
    final isVideo = (newsUrl ?? '').contains('youtube.com');

    // Correct URL logic
    if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('http')) {
      if (thumbnailUrl.startsWith('/')) {
        thumbnailUrl = '${widget.apiBaseUrl}$thumbnailUrl';
      } else {
        thumbnailUrl = '${widget.apiBaseUrl}/$thumbnailUrl';
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (newsUrl != null && newsUrl.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmbeddedWebScreen(
                  url: newsUrl,
                  appName: headline,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No article link available.')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Use a Stack to overlay the play icon on video thumbnails
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: thumbnailUrl.isNotEmpty
                        ? Image.network(
                            thumbnailUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey),
                          ),
                  ),
                  // If it's a video, show a play icon
                  if (isVideo)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      headline,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        _formatTimeAgo(article["createdAt"] ?? ''),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
