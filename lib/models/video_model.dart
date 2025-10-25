// lib/models/video_model.dart

class Video {
  final String id;
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final DateTime publishedAt;

  Video({
    required this.id,
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    // The API now provides a full, absolute URL. No need to build it.
    return Video(
      id: json['id'] ?? '',
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? 'Untitled',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      publishedAt:
          DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime(1970),
    );
  }
}
