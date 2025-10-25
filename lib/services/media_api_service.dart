// lib/services/media_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pretty_http_logger/pretty_http_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel_model.dart';
import '../models/video_model.dart';
import '../models/playlist_model.dart';

class MediaApiService {
  final String baseUrl = "http://msa.merkuz.com:3636/youtube";
  final List<String> _videoBlocklist = ['clRQNP4RdUA'];

  static final http.Client _client = HttpClientWithMiddleware.build(
    middlewares: [HttpLogger(logLevel: LogLevel.BODY)],
  );

  // --- Caching Logic ---
  Future<List<T>> _getFromCache<T>(
      String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final List<dynamic> data = json.decode(jsonString);
        return data
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print("Error reading from cache for key '$key': $e");
    }
    return [];
  }

  Future<void> _saveToCache(String key, List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(data);
      await prefs.setString(key, jsonString);
    } catch (e) {
      print("Error saving to cache for key '$key': $e");
    }
  }

  // --- Service Methods ---

  Future<List<Channel>> getChannels({bool fromCache = false}) async {
    const cacheKey = 'cached_channels';
    if (fromCache) return await _getFromCache(cacheKey, Channel.fromJson);

    try {
      final response = await _client.get(Uri.parse("$baseUrl/channels"));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        await _saveToCache(cacheKey, data);
        return (data as List).map((json) => Channel.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load channels with status code: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No Internet connection');
    } catch (e) {
      print("getChannels error: $e");
      throw Exception('Failed to load channels');
    }
  }

  Future<List<Playlist>> getPlaylists(
      {required String channelId, bool fromCache = false}) async {
    final cacheKey = 'cached_playlists_$channelId';
    if (fromCache) return await _getFromCache(cacheKey, Playlist.fromJson);

    try {
      final response = await _client
          .get(Uri.parse("$baseUrl/channels/$channelId/playlists"));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        await _saveToCache(cacheKey, data);
        List<Playlist> playlists =
            (data as List).map((json) => Playlist.fromJson(json)).toList();
        playlists.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        return playlists;
      } else {
        throw Exception('Failed to load playlists for channel: $channelId');
      }
    } on SocketException {
      throw Exception('No Internet connection');
    } catch (e) {
      print("getPlaylists error: $e");
      throw Exception('Failed to load playlists');
    }
  }

  Future<List<Video>> getVideosForPlaylist({required String playlistId}) async {
    try {
      final response =
          await _client.get(Uri.parse("$baseUrl/playlists/$playlistId/videos"));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return (data as List).map((json) => Video.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load videos for playlist: $playlistId');
      }
    } on SocketException {
      throw Exception('No Internet connection');
    } catch (e) {
      print("getVideosForPlaylist error: $e");
      throw Exception('Failed to load videos for playlist');
    }
  }

  Future<List<Video>> getAllVideosForChannel(
      {required String channelId, bool fromCache = false}) async {
    final cacheKey = 'cached_all_videos_$channelId';
    if (fromCache) {
      final cachedVideos = await _getFromCache(cacheKey, Video.fromJson);
      if (cachedVideos.isNotEmpty) return _filterAndSortVideos(cachedVideos);
    }

    final playlists = await getPlaylists(channelId: channelId);
    if (playlists.isEmpty) return [];

    final videoFutures =
        playlists.map((p) => getVideosForPlaylist(playlistId: p.id)).toList();
    final nestedVideos = await Future.wait(videoFutures);
    final allVideos = nestedVideos.expand((list) => list).toList();

    final encodableData = allVideos
        .map((v) => {
              'id': v.id,
              'videoId': v.videoId,
              'title': v.title,
              'thumbnailUrl': v.thumbnailUrl,
              'publishedAt': v.publishedAt.toIso8601String(),
            })
        .toList();

    await _saveToCache(cacheKey, encodableData);
    return _filterAndSortVideos(allVideos);
  }

  List<Video> _filterAndSortVideos(List<Video> videos) {
    List<Video> filteredList = videos
        .where((video) => !_videoBlocklist.contains(video.videoId))
        .toList();
    filteredList.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return filteredList;
  }
}
