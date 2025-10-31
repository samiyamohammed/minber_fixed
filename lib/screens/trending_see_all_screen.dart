// lib/screens/trending_see_all_screen.dart
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart'; // Import the Video model
import './video_player_screen.dart';

class TrendingSeeAllScreen extends StatefulWidget {
  final List<dynamic> trendingVideos;
  final String apiBaseUrl;

  const TrendingSeeAllScreen({
    super.key,
    required this.trendingVideos,
    required this.apiBaseUrl,
  });

  @override
  State<TrendingSeeAllScreen> createState() => _TrendingSeeAllScreenState();
}

class _TrendingSeeAllScreenState extends State<TrendingSeeAllScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending on Minber'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: widget.trendingVideos.length,
          itemBuilder: (context, index) {
            final video = widget.trendingVideos[index];
            return _buildTrendingListItem(context, video, index);
          },
        ),
      ),
    );
  }

  Widget _buildTrendingListItem(
      BuildContext context, dynamic video, int index) {
    final theme = Theme.of(context);
    String thumbnailUrl = video['thumbnail'] ?? '';

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
          final videoUrl = video['videoUrl'] as String?;
          if (videoUrl == null || videoUrl.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No video URL available.')),
            );
            return;
          }

          String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
          if (videoId != null && videoId.isNotEmpty) {
            // --- START: MODIFICATION ---

            // 1. Convert the dynamic list to a List<Video>
            final List<Video> videoPlaylist =
                widget.trendingVideos.map<Video>((item) {
              final url = item['videoUrl'] as String? ?? '';
              final id = YoutubePlayer.convertUrlToId(url) ?? '';
              String thumb = item['thumbnail'] ?? '';
              if (thumb.isNotEmpty && !thumb.startsWith('http')) {
                thumb = '${widget.apiBaseUrl}$thumb';
              }
              return Video(
                id: id, // Use videoId as a unique id
                videoId: id,
                title: item['title'] ?? 'Untitled',
                thumbnailUrl: thumb,
                publishedAt: DateTime.now(), privacyStatus: '', // No date provided, so use now
              );
            }).toList();

            // 2. Navigate with all the required parameters
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoPlayerScreen(
                  videoId: videoId,
                  initialIndex: index,
                  videoList: videoPlaylist,
                  initialVideo: videoPlaylist[index],
                ),
              ),
            );
            // --- END: MODIFICATION ---
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not play video (Invalid URL).'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 85,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: thumbnailUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey[300],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  color: Colors.grey, size: 30),
                              SizedBox(height: 4),
                              Text('No image',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.ondemand_video,
                            color: Colors.grey, size: 30),
                        SizedBox(height: 4),
                        Text('No thumbnail',
                            style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video['title'] ?? 'Untitled',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (video['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        video['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
