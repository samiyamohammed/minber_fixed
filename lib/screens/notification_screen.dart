// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/app_colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedIndex = -1;

  // Notification data
  final List<Map<String, dynamic>> _recentNotifications = [
    {
      'title': 'Prayer Alert: Dhuhur',
      'message':
          'Dhuhur prayer time starts in 10 minutes. Prepare for your prayer.',
      'time': 'Just now',
      'type': 'prayer',
      'read': false,
    },
    {
      'title': 'Order Status Update',
      'message': 'Your order #H5AP97880 for Premium Dates has been shipped!',
      'time': '1 hour ago',
      'type': 'order',
      'read': true,
    },
    {
      'title': 'Live Show Reminder',
      'message':
          'Hajal Lifestyle: Cooking with Chef Aloha starts in 15 minutes!',
      'time': '2 hours ago',
      'type': 'live',
      'read': true,
    },
    {
      'title': 'New Article Published',
      'message':
          'Discover "The Benefits of Mindful Eating" in our latest blog post.',
      'time': 'Yesterday',
      'type': 'content',
      'read': true,
    },
  ];

  final List<Map<String, dynamic>> _notificationPreferences = [
    {
      'title': 'Prayer Alerts',
      'description': 'Receive reminders for daily prayer times.',
      'enabled': true,
      'type': 'prayer',
    },
    {
      'title': 'Order Updates',
      'description': 'Get notifications on your e-commerce order status.',
      'enabled': true,
      'type': 'order',
    },
    {
      'title': 'Live Show Reminders',
      'description': 'Alerts for upcoming live media broadcasts.',
      'enabled': true,
      'type': 'live',
    },
    {
      'title': 'New Content Alerts',
      'description': 'Get notified about new articles, videos, and products.',
      'enabled': true,
      'type': 'content',
    },
    {
      'title': 'Promotional Offers',
      'description': 'Receive updates on special deals and discounts.',
      'enabled': false,
      'type': 'promo',
    },
  ];

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/media');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/prayer');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/chatBot');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/subapps');
        break;
    }
  }

  void _toggleNotificationPreference(int index) {
    setState(() {
      _notificationPreferences[index]['enabled'] =
          !_notificationPreferences[index]['enabled'];
    });

    Fluttertoast.showToast(
      msg:
          "${_notificationPreferences[index]['title']} ${_notificationPreferences[index]['enabled'] ? 'enabled' : 'disabled'}",
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'prayer':
        return Icons.mosque;
      case 'order':
        return Icons.shopping_bag;
      case 'live':
        return Icons.live_tv;
      case 'content':
        return Icons.article;
      case 'promo':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'prayer':
        return AppColors.primary;
      case 'order':
        return Colors.orange;
      case 'live':
        return Colors.purple;
      case 'content':
        return Colors.blue;
      case 'promo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: TextStyle(
            fontSize: size.width * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor ??
            AppColors.primary, // dynamic appbar color
        foregroundColor:
            theme.appBarTheme.foregroundColor ?? Colors.white, // text/icon
        elevation: 1,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: size.width * 0.03),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, "/profile");
              },
              borderRadius: BorderRadius.circular(50),
              child: CircleAvatar(
                radius: size.width * 0.05,
                backgroundImage: const AssetImage("assets/images/profile.jpg"),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent Notifications Section
            Text(
              "Recent Notifications",
              style: TextStyle(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: size.height * 0.02),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentNotifications.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: size.height * 0.02),
              itemBuilder: (context, index) {
                final notification = _recentNotifications[index];
                return Container(
                  padding: EdgeInsets.all(size.width * 0.04),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: !notification['read']
                        ? Border.all(
                            color: AppColors.primary.withOpacity(0.5),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(size.width * 0.03),
                        decoration: BoxDecoration(
                          color: _getNotificationColor(
                            notification['type'],
                          ).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotificationIcon(notification['type']),
                          color: _getNotificationColor(notification['type']),
                          size: size.width * 0.05,
                        ),
                      ),
                      SizedBox(width: size.width * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification['title'],
                              style: TextStyle(
                                fontSize: size.width * 0.04,
                                fontWeight: FontWeight.bold,
                                color: !notification['read']
                                    ? AppColors.primary
                                    : theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            SizedBox(height: size.height * 0.005),
                            Text(
                              notification['message'],
                              style: TextStyle(
                                fontSize: size.width * 0.035,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: size.height * 0.005),
                            Text(
                              notification['time'],
                              style: TextStyle(
                                fontSize: size.width * 0.03,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!notification['read'])
                        Container(
                          width: size.width * 0.02,
                          height: size.width * 0.02,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: size.height * 0.04),
            Divider(color: theme.dividerColor),
            SizedBox(height: size.height * 0.04),

            // Notification Preferences Section
            Text(
              "Notification Preferences",
              style: TextStyle(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: size.height * 0.02),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notificationPreferences.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: size.height * 0.02),
              itemBuilder: (context, index) {
                final preference = _notificationPreferences[index];
                return Container(
                  padding: EdgeInsets.all(size.width * 0.04),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(size.width * 0.03),
                        decoration: BoxDecoration(
                          color: _getNotificationColor(
                            preference['type'],
                          ).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotificationIcon(preference['type']),
                          color: _getNotificationColor(preference['type']),
                          size: size.width * 0.05,
                        ),
                      ),
                      SizedBox(width: size.width * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preference['title'],
                              style: TextStyle(
                                fontSize: size.width * 0.04,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            SizedBox(height: size.height * 0.005),
                            Text(
                              preference['description'],
                              style: TextStyle(
                                fontSize: size.width * 0.035,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: preference['enabled'],
                        onChanged: (value) =>
                            _toggleNotificationPreference(index),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: size.height * 0.03),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex < 0 ? 0 : _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: theme.unselectedWidgetColor,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: size.width * 0.03,
        unselectedFontSize: size.width * 0.03,
        iconSize: size.width * 0.06,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: size.width * 0.06),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tv, size: size.width * 0.06),
            label: "Media",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mosque, size: size.width * 0.06),
            label: "Prayer",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline, size: size.width * 0.06),
            activeIcon: Icon(Icons.chat_bubble, size: size.width * 0.06),
            label: "ChatBot",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore, size: size.width * 0.06),
            label: "Sub Apps",
          ),
        ],
      ),
    );
  }
}
