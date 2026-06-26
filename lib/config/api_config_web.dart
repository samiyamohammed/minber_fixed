// Web-specific API configuration with CORS proxy
class ApiConfig {
  // Use CORS proxy for web demo
  static const String corsProxy = 'https://corsproxy.io/?';
  static const String originalBaseUrl = 'http://msa.merkuz.com:3636';
  static const String originalStreamUrl = 'http://msa.merkuz.com:8888';
  
  // Proxied URLs for web
  static const String baseUrl = '${corsProxy}${originalBaseUrl}';
  static const String streamUrl = '${corsProxy}${originalStreamUrl}/live/stream1/index.m3u8';
  
  // API endpoints
  static String get trendingUrl => '$baseUrl/trending';
  static String get newsUrl => '$baseUrl/news';
  static String get youtubeUrl => '$baseUrl/youtube';
  static String get usersUrl => '$baseUrl/users';
  static String get geminiUrl => '$baseUrl/gemini';
}
