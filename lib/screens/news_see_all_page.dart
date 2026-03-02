import 'package:flutter/material.dart';
import '../widgets/embedded_web_screen.dart';
import '../core/app_colors.dart'; // Ensure this is imported for consistent colors

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

class _NewsSeeAllPageState extends State<NewsSeeAllPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<dynamic> _articleNews;
  late List<dynamic> _videoNews;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

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
    _tabController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 365)
        return '${(difference.inDays / 365).floor()}y ago';
      if (difference.inDays > 30)
        return '${(difference.inDays / 30).floor()}mo ago';
      if (difference.inDays > 0) return '${difference.inDays}d ago';
      if (difference.inHours > 0) return '${difference.inHours}h ago';
      if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latest News'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryBlue,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Articles'),
            Tab(text: 'Video News'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewsList(widget.newsArticles),
          _buildNewsList(_articleNews),
          _buildNewsList(_videoNews),
        ],
      ),
    );
  }

  Widget _buildNewsList(List<dynamic> articles) {
    if (articles.isEmpty) {
      return const Center(
        child: Text('No items in this category.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          return _buildNewsListItem(context, articles[index]);
        },
      ),
    );
  }

  Widget _buildNewsListItem(BuildContext context, dynamic article) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final headline = article['headline'] ?? 'No Title';
    final newsUrl = article['newsUrl'] as String?;
    String thumbnailUrl = article['thumbnail'] ?? '';
    final isVideo = (newsUrl ?? '').contains('youtube.com');

    if (thumbnailUrl.isNotEmpty && !thumbnailUrl.startsWith('http')) {
      thumbnailUrl = thumbnailUrl.startsWith('/')
          ? '${widget.apiBaseUrl}$thumbnailUrl'
          : '${widget.apiBaseUrl}/$thumbnailUrl';
    }

    final cardColor =
        isDarkMode ? AppColors.surfaceDark : const Color(0xFFF7F9FC);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (newsUrl != null && newsUrl.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EmbeddedWebScreen(url: newsUrl, appName: headline),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. LARGE IMAGE FRAME
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: thumbnailUrl.isNotEmpty
                      ? Image.network(
                          thumbnailUrl,
                          width: double.infinity,
                          height: 220, // Taller image for the see-all page
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: double.infinity,
                            height: 220,
                            color: theme.splashColor,
                            child: const Icon(Icons.broken_image, size: 50),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          height: 220,
                          color: theme.splashColor,
                          child: const Icon(Icons.image, size: 50),
                        ),
                ),
                // Overlay Play Icon if it's a video
                if (isVideo)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 50),
                  ),
              ],
            ),

            // 2. TEXT CONTENT
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: theme.hintColor),
                      const SizedBox(width: 6),
                      Text(
                        _formatTimeAgo(article["createdAt"] ?? ''),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                      const Spacer(),
                      // Optional: Label to show "Video" vs "Article"
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isVideo
                              ? Colors.red.withOpacity(0.1)
                              : AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isVideo ? "VIDEO" : "ARTICLE",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isVideo ? Colors.red : AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
