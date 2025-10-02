import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/app_colors.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  int _selectedIndex = 3; // 👈 Default = Chat Bot tab
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [
    {'sender': 'user', 'text': 'What are the prayer times for my location?'},
    {
      'sender': 'ai',
      'text':
          'I can help with that. Please provide your current location or enable location services for precise prayer times.',
    },
    {
      'sender': 'user',
      'text': 'Can you recommend a good Hala! movie to watch tonight?',
    },
    {
      'sender': 'user',
      'text': 'I\'m looking for a new Islamic podcast. Any suggestions?',
    },
    {
      'sender': 'ai',
      'text':
          'Certainly! Based on your interests, \'The Seerah Podcast\' by Yasir Qadhi',
    },
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // avoid reloading same tab

    setState(() {
      _selectedIndex = index;
    });

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
        // already on Chat Bot
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/subapps');
        break;
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _chatMessages.add({'sender': 'user', 'text': _messageController.text});
      _messageController.clear();
    });

    // Simulate AI response after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _chatMessages.add({
          'sender': 'ai',
          'text': 'I understand your question. Let me help you with that.',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "AI Assistant",
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: size.width * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, size: size.width * 0.06),
            onPressed: () {
              Navigator.pushNamed(context, "/notifications");
            },
          ),
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
      body: Column(
        children: [
          // Welcome message
          Container(
            padding: EdgeInsets.all(size.width * 0.04),
            color: theme.cardColor,
            child: Row(
              children: [
                CircleAvatar(
                  radius: size.width * 0.06,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Icon(
                    Icons.smart_toy_outlined,
                    color: AppColors.primary,
                    size: size.width * 0.06,
                  ),
                ),
                SizedBox(width: size.width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello! I'm your Hala! Assistant.",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: size.width * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "How can I assist you today?",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: size.width * 0.035,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: size.height * 0.01),

          // Quick action buttons
          Container(
            padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
            color: theme.cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  context,
                  "Prayer Times",
                  Icons.access_time,
                  () {
                    Navigator.pushNamed(context, '/prayer-times');
                  },
                ),
                _buildQuickActionButton(
                  context,
                  "Movie Recommendations",
                  Icons.movie,
                  () {
                    Fluttertoast.showToast(
                      msg: "Movie recommendations clicked",
                    );
                  },
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(size.width * 0.04),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                final isUser = message['sender'] == 'user';

                return Container(
                  margin: EdgeInsets.only(bottom: size.height * 0.02),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isUser)
                        CircleAvatar(
                          radius: size.width * 0.045,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Icon(
                            Icons.smart_toy_outlined,
                            color: AppColors.primary,
                            size: size.width * 0.045,
                          ),
                        ),
                      if (!isUser) SizedBox(width: size.width * 0.03),
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.all(size.width * 0.04),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppColors.primary.withOpacity(0.1)
                                : theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: theme.dividerColor.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            message['text']!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: size.width * 0.04,
                            ),
                          ),
                        ),
                      ),
                      if (isUser) SizedBox(width: size.width * 0.03),
                      if (isUser)
                        CircleAvatar(
                          radius: size.width * 0.045,
                          backgroundImage: const AssetImage(
                            "assets/images/profile.jpg",
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: EdgeInsets.all(size.width * 0.04),
            color: theme.cardColor,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                    ),
                    decoration: BoxDecoration(
                      color:
                          theme.inputDecorationTheme.fillColor ??
                          theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        border: InputBorder.none,
                        hintStyle: theme.textTheme.bodySmall,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.send, color: AppColors.primary),
                          onPressed: _sendMessage,
                        ),
                      ),
                      onSubmitted: (value) => _sendMessage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: theme.iconTheme.color?.withOpacity(0.6),
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
            label: "Watch",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mosque, size: size.width * 0.06),
            label: "Prayer",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline, size: size.width * 0.06),
            activeIcon: Icon(Icons.chat_bubble, size: size.width * 0.06),
            label: "Chat Box",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore, size: size.width * 0.06),
            label: "Sub Apps",
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.01,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: size.width * 0.045),
            SizedBox(width: size.width * 0.02),
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: size.width * 0.035,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
