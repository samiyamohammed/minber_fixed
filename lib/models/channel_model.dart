// lib/models/channel_model.dart

class Channel {
  final String id;
  final String title;
  final String thumbnailUrl;

  const Channel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled Channel',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
    );
  }
}
