// lib/screens/chat_history_screen.dart (Fully Updated & Ready to Paste)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatHistoryScreen extends StatefulWidget {
  final List<Map<String, String>> initialHistory;
  final Function() onHistoryCleared; // Callback to notify main chat page

  const ChatHistoryScreen({
    super.key,
    required this.initialHistory,
    required this.onHistoryCleared,
  });

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _history = List.from(widget.initialHistory); // Create a mutable copy
  }

  // This function is already perfect. It handles all the logic correctly.
  Future<void> _clearChatHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history'); // Remove the key from preferences
    setState(() {
      _history.clear(); // Clear local history list to show the "empty" state
    });
    widget.onHistoryCleared(); // Notify the main chat page to clear its history

    // Check if the widget is still in the tree before navigating or showing a snackbar
    if (!mounted) return;

    Navigator.of(context).pop(); // Go back to the chat page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat history cleared!')),
    );
  }

  // ✅ Helper function to show the confirmation dialog
  void _showClearConfirmationDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Clear History?'),
          content: const Text(
              'Are you sure you want to delete all chat history? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
              },
            ),
            // Use a filled button for the destructive action to make it stand out
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Clear'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss the dialog
                _clearChatHistory(); // Proceed with clearing history
              },
            ),
          ],
        );
      },
    );
  }

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isDarkMode;

    final botTextStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDark ? Colors.white : Colors.black87,
      fontSize: 15,
      height: 1.4,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat History"),
        centerTitle: true,
        backgroundColor:
            Colors.transparent, // Makes the app bar background see-through
        elevation: 0,
        // ✅ ADDED a clear history button to the AppBar actions
        actions: [
          if (_history.isNotEmpty) // Only show the button if there is history
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined),
              tooltip: "Clear History",
              onPressed:
                  _showClearConfirmationDialog, // Call the confirmation dialog
            ),
        ],
      ),
      body: _history.isEmpty
          ? Center(
              child: Text(
                "No chat history available.",
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.hintColor),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final message = _history[index];
                final isUser = message["sender"] == "user";

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser
                          ? theme.primaryColor.withOpacity(0.9)
                          : (isDark ? Colors.white10 : Colors.grey.shade200),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: isUser
                        ? SelectableText(
                            message["text"] ?? "",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          )
                        : MarkdownBody(
                            data: message["text"] ?? "",
                            selectable: true,
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(theme).copyWith(
                              p: botTextStyle,
                              strong: botTextStyle?.copyWith(
                                  fontWeight: FontWeight.bold),
                              listBullet: botTextStyle,
                              listIndent: 24.0,
                            ),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
