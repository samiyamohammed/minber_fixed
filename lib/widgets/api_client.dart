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
// --- THIS IS THE MAGIC ---
// Check if the error is a 401 Unauthorized
          if (err.response?.statusCode == 401) {
            logger.w(
                ' получили 401 Unauthorized error. Attempting to refresh token...');
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

// --- Your new API methods will go here ---
  /// Updates the user's profile.
  Future<Map<String, dynamic>> updateUserProfile(
      String name, String email) async {
    // ✅ ADD A TRY-CATCH BLOCK AROUND THE API CALL
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
      // ✅ LOG THE FULL DIO ERROR. This is the key to solving the problem.
      logger.e(
        "🔥 API CLIENT ERROR on updateUserProfile",
        error: "Message: ${e.message}, Response: ${e.response?.data}",
        stackTrace: e.stackTrace,
      );
      // Re-throw the error so the UI can catch it and show the SnackBar
      throw e;
    }
  }
}
