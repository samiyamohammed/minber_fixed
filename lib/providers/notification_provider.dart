// lib/providers/notification_provider.dart (CHAIN OF EVIDENCE VERSION)

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/notifications_api.dart';

class NotificationProvider with ChangeNotifier {
  final Logger _logger = Logger();

  List<dynamic> _notifications = [];
  Set<String> _readNotifications = {};
  bool _isLoading = false;

  static const _notificationLimit = 10;
  static const _readNotificationsKey = 'read_notifications_set';

  // --- GETTERS (unchanged) ---
  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) {
        final notificationId = n['id']?.toString();
        return notificationId != null &&
            !_readNotifications.contains(notificationId);
      }).length;
  bool isRead(String notificationId) =>
      _readNotifications.contains(notificationId);

  // --- METHODS (unchanged) ---
  Future<void> init() async {
    await _loadReadNotifications();
    await fetchNotifications();
  }

  Future<void> _loadReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_readNotificationsKey);
    if (savedIds != null) {
      _readNotifications = savedIds.toSet();
      _logger.i("✅ Loaded ${_readNotifications.length} read IDs from storage.");
    }
  }

  Future<void> _saveReadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _readNotificationsKey, _readNotifications.toList());
    _logger.d(
        "💾 Saved read state. Current read IDs: ${_readNotifications.toList()}");
  }

  Future<void> markAsUnreadAndRefresh(String notificationId) async {
    _logger.i(
        "Foreground Trigger: Forcing '$notificationId' to be unread and refreshing.");

    if (_readNotifications.contains(notificationId)) {
      _readNotifications.remove(notificationId);
      await _saveReadNotifications(); // Save the updated list to SharedPreferences
    }
    await fetchNotifications();
  }


  Future<void> fetchNotifications() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      var fetchedItems = await NotificationsApi.fetchNotifications();
      fetchedItems.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['updatedAt'] ?? a['createdAt']);
          final dateB = DateTime.parse(b['updatedAt'] ?? b['createdAt']);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
      _notifications = fetchedItems.length > _notificationLimit
          ? fetchedItems.take(_notificationLimit).toList()
          : fetchedItems;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ --- ALTERNATIVE: MORE EXPLICIT VERSION --- ✅
  void promoteNotificationFromPush(Map<String, dynamic> notificationData) {
    final String notificationId = notificationData['id'].toString();
    _logger.i(
        "--- [PUSH PROMOTION] Making notification '$notificationId' UNREAD ---");

    // 🔥 FORCE UNREAD: Explicitly ensure the notification is NOT in the read set
    bool wasRead = _readNotifications.contains(notificationId);

    if (wasRead) {
      _readNotifications.remove(notificationId);
      _logger.i("🔄 Converted READ notification '$notificationId' to UNREAD");
    } else {
      _logger.i("📱 Notification '$notificationId' is already UNREAD");
    }

    // Remove any existing instance and add the fresh notification data to top
    final List<dynamic> newNotifications = [
      notificationData,
      ..._notifications.where((n) => n['id']?.toString() != notificationId),
    ];
    _notifications = newNotifications.length > _notificationLimit
        ? newNotifications.take(_notificationLimit).toList()
        : newNotifications;

    _logger.i("🎯 Push notification promoted. Unread count: $unreadCount");

    notifyListeners();
    _saveReadNotifications();
  }

  void markAsRead(String notificationId) {
    if (_readNotifications.add(notificationId)) {
      _logger.i("Marked '$notificationId' as read.");
      notifyListeners();
      _saveReadNotifications();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      if (n['id'] != null) _readNotifications.add(n['id'].toString());
    }
    notifyListeners();
    _saveReadNotifications();
  }
}
