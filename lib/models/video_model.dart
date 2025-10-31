// lib/models/video_model.dart

class Video {
  final String id;
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final DateTime publishedAt;
  final String privacyStatus; // Added this line

  Video({
    required this.id,
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.publishedAt,
    required this.privacyStatus, // Added this line
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? '',
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? 'Untitled',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      publishedAt:
          DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime(1970),
      privacyStatus: json['privacyStatus'] ?? 'public', // Added this line
    );
  }
}