import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../providers/user_provider.dart';

class ApiClient {
  final Dio _dio;
  final UserProvider _userProvider;
  final logger = Logger();

  ApiClient(this._userProvider)
      : _dio = Dio(BaseOptions(baseUrl: 'http://msa.merkuz.com:3636')) {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          // Add the access token to every request
          if (_userProvider.accessToken != null) {
            options.headers['Authorization'] =
                'Bearer ${_userProvider.accessToken}';
          }
          logger.i('🚀 Sending request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onError: (DioException err, handler) async {
          // Check if the error is a 401 Unauthorized
          if (err.response?.statusCode == 401) {
            logger.w(
                'Received 401 Unauthorized error. Attempting to refresh token...');

            // Avoid infinite loops: if the refresh token call itself fails, don't retry.
            if (err.requestOptions.path == '/users/refresh-token') {
              logger.e('🚨 Refresh token failed. Logging out.');
              _userProvider.logout();
              return handler.reject(err);
            }

            try {
              // 1. Get new tokens
              final newTokens = await _refreshToken();
              final newAccessToken = newTokens['accessToken'];
              final newRefreshToken = newTokens['refreshToken'];

              // 2. Save new tokens
              await _userProvider.updateTokens(newAccessToken, newRefreshToken);

              // 3. Retry the original failed request with the new token
              logger.i('✅ Token refreshed. Retrying original request...');
              final response = await _dio.fetch(
                err.requestOptions
                  ..headers['Authorization'] = 'Bearer $newAccessToken',
              );
              return handler.resolve(response);
            } on DioException catch (e) {
              // If refreshing the token fails, logout the user
              logger.e('😭 Could not refresh token. Logging out.', error: e);
              _userProvider.logout();
              return handler.reject(e);
            }
          }
          return handler.next(err);
        },
      ),
    );
  }

  /// Calls the refresh token endpoint.
  Future<Map<String, dynamic>> _refreshToken() async {
    final refreshToken = _userProvider.refreshToken;
    if (refreshToken == null) {
      throw Exception("No refresh token available.");
    }

    final response = await _dio.post(
      '/users/refresh-token',
      data: {'refreshToken': refreshToken},
    );
    return response.data;
  }

  /// Updates the user's profile.
  Future<Map<String, dynamic>> updateUserProfile(
      String name, String email) async {
    try {
      logger.i("Attempting to update profile with name: $name, email: $email");
      final response = await _dio.put(
        '/users/profile',
        data: {'name': name, 'email': email},
      );
      logger
          .i("✅ Profile update successful. Server response: ${response.data}");
      return response.data;
    } on DioException catch (e) {
      logger.e(
        "🔥 API CLIENT ERROR on updateUserProfile",
        error: "Message: ${e.message}, Response: ${e.response?.data}",
        stackTrace: e.stackTrace,
      );
      throw e;
    }
  }

  /// Fetches the active Ramadan questions for today.
  Future<List<dynamic>> getActiveRamadanQuestions() async {
    try {
      logger.i("Fetching active Ramadan questions...");
      final response = await _dio.get('/questions/active');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      logger.e("Error fetching Ramadan questions", error: e.response?.data);
      throw e;
    }
  }

  /// Submits an answer for a specific question.
  Future<Map<String, dynamic>> submitRamadanAnswer(
      String questionId, String optionId) async {
    try {
      logger.i("Submitting answer for question $questionId, option $optionId");
      final response = await _dio.post(
        '/questions/$questionId/answer',
        data: {'optionId': optionId},
      );
      return response.data;
    } on DioException catch (e) {
      logger.e("Error submitting Ramadan answer", error: e.response?.data);
      throw e;
    }
  }

  /// NEW: Fetches the user's quiz participation history.
  Future<List<dynamic>> getRamadanUserHistory() async {
    try {
      logger.i("Fetching user Ramadan quiz history...");
      final response = await _dio.get('/questions/history');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      logger.e("Error fetching Ramadan history", error: e.response?.data);
      throw e;
    }
  }

  /// NEW: Fetches the top 10 participants for the leaderboard.
  Future<Map<String, dynamic>> getRamadanLeaderboardTop10() async {
    try {
      logger.i("Fetching top 10 leaderboard...");
      final response = await _dio.get('/questions/leaderboard/top10');
      // Returns { "year": "2026", "top10": [...] }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      logger.e("Error fetching Ramadan leaderboard", error: e.response?.data);
      throw e;
    }
  }
}
