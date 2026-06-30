import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class NotificationsApi {
  // Initialize a logger for this class
  static final logger = Logger(
    printer: PrettyPrinter(methodCount: 1, printTime: true),
  );

  // The base URL from your original code
  static const String baseUrl = 'https://msa.merkuz.com';

  static Future<List<dynamic>> fetchNotifications() async {
    final url = '$baseUrl/notifications';
    logger.i("Attempting to fetch notifications from: $url");

    try {
      final response = await http.get(Uri.parse(url));

      // Log the server's full response for debugging
      logger.d({
        "URL": url,
        "Status Code": response.statusCode,
        "Response Body": response.body,
      });

      if (response.statusCode == 200) {
        // Decode the JSON from the response body
        final data = json.decode(response.body);

        // Ensure the decoded data is a List, as expected
        if (data is List) {
          logger.i(
            "✅ Successfully fetched and parsed ${data.length} notifications.",
          );
          return data;
        } else {
          // This handles cases where the API might return an error object instead of a list
          logger.e(
            "❌ API response was not a List as expected. Type was: ${data.runtimeType}",
          );
          throw Exception('API response format is incorrect.');
        }
      } else {
        // Handle server errors like 404 Not Found or 500 Internal Server Error
        logger.e(
          "❌ API returned a non-200 status code: ${response.statusCode}",
        );
        throw Exception(
          'Failed to load notifications (Status code: ${response.statusCode})',
        );
      }
    } catch (e, s) {
      // Catch any other errors (e.g., no internet connection, DNS failure)
      logger.e(
        "💀 An error occurred during the notification fetch process.",
        error: e,
        stackTrace: s,
      );
      // Re-throw the exception so the UI can display an appropriate error message
      throw Exception('Failed to fetch notifications. Error: $e');
    }
  }

  /// Fetch a single notification by its id.
  static Future<Map<String, dynamic>?> fetchNotificationById(String id) async {
    final url = '$baseUrl/notifications/$id';
    logger.i("Attempting to fetch single notification from: $url");
    try {
      final response = await http.get(Uri.parse(url));
      logger.d({
        "URL": url,
        "Status Code": response.statusCode,
        "Response Body": response.body,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          logger.i("✅ Successfully fetched notification with id=$id");
          return data;
        } else if (data is List && data.isNotEmpty) {
          // Some APIs return a single item wrapped in a list
          return Map<String, dynamic>.from(data.first);
        } else {
          logger.w("⚠️ Unexpected payload when fetching notification $id");
          return null;
        }
      } else {
        logger.e(
            "❌ API returned non-200 for single notification: ${response.statusCode}");
        return null;
      }
    } catch (e, s) {
      logger.e("💀 Error fetching notification by id: $e",
          error: e, stackTrace: s);
      return null;
    }
  }
}
