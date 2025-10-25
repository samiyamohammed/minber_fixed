// lib/screens/news_see_all_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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

class _NewsSeeAllPageState extends State<NewsSeeAllPage> {
  // Helper function to format date strings into "time ago" format
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
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // This would refresh the data when pulled down
          // In a real app, you might want to pass a refresh callback from the parent
          setState(() {});
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: widget.newsArticles.length,
          itemBuilder: (context, index) {
            final article = widget.newsArticles[index];
            return _buildNewsListItem(context, article, index);
          },
        ),
      ),
    );
  }

  Widget _buildNewsListItem(BuildContext context, dynamic article, int index) {
    final theme = Theme.of(context);
    final headline = article['headline'] ?? 'No Title';
    final newsUrl = article['newsUrl'] as String?;
    String thumbnailUrl = article['thumbnail'] ?? '';

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
