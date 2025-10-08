import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class NotificationsApi {
  // Initialize a logger for this class
  static final logger = Logger(
    printer: PrettyPrinter(methodCount: 1, printTime: true),
  );

  // The base URL from your original code
  static const String baseUrl = 'http://msa.merkuz.com:3636';

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
}
