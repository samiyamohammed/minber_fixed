import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../providers/user_provider.dart';
import '../config/api_config_web.dart';

class ApiClient {
  final Dio _dio;
  final UserProvider _userProvider;
  final logger = Logger();

  ApiClient(this._userProvider)
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          // set reasonable timeouts at the HTTP client level rather than
          // using Future.timeout in every call. 10 seconds is what the
          // provider was using previously.
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
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
  ///
  /// The backend wraps every response in an envelope containing
  /// `success`, `message`, `data`, etc.  We return the entire body so the
  /// caller can inspect the message and unwrap the `data` field lazily.
  Future<Map<String, dynamic>> getActiveRamadanQuestions() async {
    try {
      logger.i("Fetching active Ramadan questions...");
      final response = await _dio.get('/questions/active');

      // ensure we always return a map so the provider code can safely
      // index into it; some endpoints may erroneously send a list but
      // the envelope is the norm.
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }

      // fallback: wrap non-map data in a fake envelope
      logger.w(
          'getActiveRamadanQuestions received non-map payload: ${response.data}');
      return {'data': response.data};
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

  /// Fetches the user's quiz participation history.
  ///
  /// History is also wrapped in the standard envelope.  We return
  /// the unwrapped list so callers don't need to perform the check.
  Future<List<dynamic>> getRamadanUserHistory() async {
    try {
      logger.i("Fetching user Ramadan quiz history...");
      final response = await _dio.get('/questions/history');
      final data = response.data;
      if (data is Map && data.containsKey('data')) {
        return (data['data'] as List<dynamic>?) ?? [];
      }
      if (data is List) return data;
      logger.w('Unexpected history payload: $data');
      return [];
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
      final result = response.data;
      if (result is Map<String, dynamic>) return result;

      logger.w('Unexpected leaderboard payload: $result');
      // wrap in map to keep return type consistent
      return {'top10': []};
    } on DioException catch (e) {
      logger.e("Error fetching Ramadan leaderboard", error: e.response?.data);
      throw e;
    }
  }
}
