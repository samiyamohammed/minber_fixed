// Web-specific API configuration with HTTPS backend
class ApiConfig {
  // Backend now supports HTTPS!
  static const String baseUrl = 'https://msa.merkuz.com';
  static const String streamUrl = 'http://msa.merkuz.com:8888/live/stream1/index.m3u8';
  
  // API endpoints
  static String get trendingUrl => '$baseUrl/trending';
  static String get newsUrl => '$baseUrl/news';
  static String get youtubeUrl => '$baseUrl/youtube';
  static String get usersUrl => '$baseUrl/users';
  static String get geminiUrl => '$baseUrl/gemini';
}
