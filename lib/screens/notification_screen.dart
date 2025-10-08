import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../api/notifications_api.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<dynamic>> _notificationsFuture;
  final logger = Logger(printer: PrettyPrinter(methodCount: 0));

  @override
  void initState() {
    super.initState();
    _notificationsFuture = NotificationsApi.fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<dynamic>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          logger.d("FutureBuilder state: ${snapshot.connectionState}");

          // State 1: Still loading data from the server
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // State 2: An error occurred during the fetch
          else if (snapshot.hasError) {
            logger.e("FutureBuilder caught an error", error: snapshot.error);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '❌ Something went wrong.\nPlease check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700], fontSize: 16),
                ),
              ),
            );
          }
          // State 3: The request succeeded, but the list of notifications is empty
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            logger.i(
              "FutureBuilder received an empty list. Displaying 'No notifications'.",
            );
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'You have no new notifications.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // State 4: Everything succeeded, and we have notifications to display
          final notifications = snapshot.data!;
          logger.i(
            "FutureBuilder has data. Displaying ${notifications.length} notifications.",
          );
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: Text(n['title'] ?? 'Untitled'),
                  //
                  // ▼▼▼▼ THE FIX IS HERE ▼▼▼▼
                  //
                  subtitle: Text(n['body'] ?? 'No message content.'),
                  //
                  // ▲▲▲▲ THE FIX IS HERE ▲▲▲▲
                  //
                ),
              );
            },
          );
        },
      ),
    );
  }
}
