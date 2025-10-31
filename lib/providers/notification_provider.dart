// lib/providers/notification_provider.dart (FINAL - Limit 10)

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/notifications_api.dart';

class NotificationProvider with ChangeNotifier {
  final Logger _logger = Logger();

  List<dynamic> _notifications = [];
  Set<String> _readNotifications = {};
  bool _isLoading = false;

  // --- ✅ THE ONLY CHANGE IS HERE: Changed 50 to 10 ---
  static const _notificationLimit = 10; // Only show the 10 newest notifications
  static const _readNotificationsKey = 'read_notifications_set';

  // --- GETTERS ---
  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) {
        final notificationId = n['id']?.toString();
        return notificationId != null &&
            !_readNotifications.contains(notificationId);
      }).length;

  bool isRead(String notificationId) =>
      _readNotifications.contains(notificationId);

  // --- ROBUST INITIALIZATION METHOD ---
  Future<void> init() async {
    await _loadReadNotifications();
    await fetchNotifications(); // Fetch initial data after loading state
  }

  // --- Data Persistence Methods ---
  Future<void> _loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_readNotificationsKey);
    if (savedIds != null) {
      _readNotifications = savedIds.toSet();
      _logger.i(
          "✅ Loaded ${_readNotifications.length} read notification IDs from storage.");
    }
  }

  Future<void> _saveReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _readNotificationsKey, _readNotifications.toList());
    _logger.d("💾 Saved read notifications state to device.");
  }

  // --- Public Methods ---

  /// Fetches, sorts, and limits notifications from the API.
  Future<void> fetchNotifications() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      var fetchedItems = await NotificationsApi.fetchNotifications();

      // Sort notifications by 'createdAt' date, newest first.
      fetchedItems.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['createdAt']);
          final dateB = DateTime.parse(b['createdAt']);
          return dateB.compareTo(dateA); // Newest first
        } catch (e) {
          // If date parsing fails, treat them as equal
          return 0;
        }
      });

      // Limit the number of notifications
      if (fetchedItems.length > _notificationLimit) {
        _notifications = fetchedItems.take(_notificationLimit).toList();
      } else {
        _notifications = fetchedItems;
      }

      _logger
          .i("✅ Fetched and processed ${_notifications.length} notifications.");
    } catch (e) {
      _logger.e("❌ Failed to fetch notifications: $e");
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marks a single notification as read and saves the state.
  void markAsRead(String notificationId) {
    if (!_readNotifications.contains(notificationId)) {
      _readNotifications.add(notificationId);
      _logger.i("Marked notification as read: $notificationId");
      notifyListeners();
      _saveReadNotifications(); // Save state
    }
  }

  /// Marks all currently loaded notifications as read and saves the state.
  void markAllAsRead() {
    for (var n in _notifications) {
      final notificationId = n['id']?.toString();
      if (notificationId != null) {
        _readNotifications.add(notificationId);
      }
    }
    _logger.i("Marked all ${_notifications.length} notifications as read.");
    notifyListeners();
    _saveReadNotifications(); // Save state
  }
}
