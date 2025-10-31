// lib/screens/notification_screen.dart (FIXED)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/notification_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNotifications();
    });
  }

  Future<void> _refreshNotifications() async {
    await Provider.of<NotificationProvider>(context, listen: false)
        .fetchNotifications();
  }

  String _formatTimestamp(String? dateString) {
    if (dateString == null) return '';
    try {
      final dateTime = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        if (difference.inHours < 1) {
          if (difference.inMinutes < 1) return 'Just now';
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${DateFormat.jm().format(dateTime)}';
      } else {
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () {
              notificationProvider.markAllAsRead();
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: _buildBody(notificationProvider),
      ),
    );
  }

  Widget _buildBody(NotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const _NotificationListShimmer();
    }
    if (!provider.isLoading && provider.notifications.isEmpty) {
      return const _EmptyState(
        icon: Icons.notifications_off_outlined,
        message: 'No New Notifications',
        description: "You're all caught up!",
      );
    }

    final notifications = provider.notifications;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final n = notifications[index];
        // ✅ FIXED: Changed '_id' to 'id' to match your API response.
        final notificationId = n['id']?.toString() ?? index.toString();
        final isRead = provider.isRead(notificationId);

        return _NotificationItem(
          key: ValueKey(notificationId),
          title: n['title'] ?? 'Untitled Notification',
          body: n['body'] ?? 'No message content.',
          timestamp: _formatTimestamp(n['createdAt']),
          isRead: isRead,
          onTap: () {
            provider.markAsRead(notificationId);
          },
        );
      },
    );
  }
}

// --- WIDGETS (Paste your existing _NotificationItem, _NotificationListShimmer, and _EmptyState widgets here) ---

class _NotificationItem extends StatelessWidget {
  final String title;
  final String body;
  final String timestamp;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationItem({
    super.key,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    required this.onTap,
  });

  IconData _getIconForNotification(String title) {
    title = title.toLowerCase();
    if (title.contains('live') ||
        title.contains('show') ||
        title.contains('video')) {
      return Icons.play_circle_outline_rounded;
    }
    if (title.contains('prayer') || title.contains('adhan')) {
      return Icons.mosque_outlined;
    }
    if (title.contains('reminder') || title.contains('event')) {
      return Icons.event_note_outlined;
    }
    return Icons.notifications_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final icon = _getIconForNotification(title);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color:
          isRead ? Colors.transparent : colorScheme.primary.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isRead ? theme.hintColor : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (timestamp.isNotEmpty)
                      Text(
                        timestamp,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationListShimmer extends StatelessWidget {
  const _NotificationListShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.splashColor,
      highlightColor: theme.cardColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: 10,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 22, backgroundColor: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white),
                    const SizedBox(height: 8),
                    Container(
                        width: double.infinity,
                        height: 14,
                        color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 100, height: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String description;
  final VoidCallback? onRetry;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.description,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: theme.hintColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(message,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor)),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: onRetry,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
