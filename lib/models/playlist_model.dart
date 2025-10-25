// lib/models/playlist_model.dart

class Playlist {
  final String id;
  final String title;
  final String thumbnailUrl;
  final DateTime publishedAt;

  Playlist({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Playlist',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      publishedAt:
          DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime(1970),
    );
  }
}
