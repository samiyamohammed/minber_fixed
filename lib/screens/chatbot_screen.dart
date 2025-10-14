// lib/screens/chatbot_screen.dart (Fully Updated & Ready to Paste)

import 'dart:async';
import 'package:flutter/material.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final int _selectedIndex = 3; // For BottomNavBar highlighting
  final TextEditingController _messageController = TextEditingController();

  // ✅ UI/UX UPDATE: Keys for animating the list and controlling scroll
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    // Start with an initial welcome message from the AI
    _addInitialMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addInitialMessage() {
    // Add the first message without animation when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatMessages.add({
        'sender': 'ai',
        'text':
            "Hello! I'm your Minber TV Assistant. How can I help you today?",
      });
      setState(() {});
    });
  }

  // Helper function to add a message to the list with an animation
  void _addMessage(String sender, String text) {
    // Insert new message into the list
    final index = _chatMessages.length;
    _chatMessages.add({'sender': sender, 'text': text});

    // Animate the insertion
    _listKey.currentState?.insertItem(
      index,
      duration: const Duration(milliseconds: 400),
    );

    // ✅ UI/UX UPDATE: Automatically scroll to the bottom
    _scrollToBottom();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    _addMessage('user', text);
    _messageController.clear();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1000), () {
      _addMessage(
          'ai', 'Thank you for your question. I am processing your request...');
    });
  }

  void _scrollToBottom() {
    // Wait a moment for the list to build, then scroll
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- NAVIGATION (Simplified) ---
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
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
        break; // Already here
      case 4:
        Navigator.pushReplacementNamed(context, '/subapps');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Assistant"),
        elevation: 1,
      ),
      body: Column(
        children: [
          // ✅ UI/UX UPDATE: Quick action suggestion chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            color: theme.scaffoldBackgroundColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _buildQuickActionChip(
                      "Prayer Times", Icons.access_time_filled_rounded),
                  const SizedBox(width: 8),
                  _buildQuickActionChip(
                      "Find a Show", Icons.movie_filter_rounded),
                  const SizedBox(width: 8),
                  _buildQuickActionChip(
                      "Qibla Direction", Icons.explore_rounded),
                ],
              ),
            ),
          ),

          // ✅ UI/UX UPDATE: Chat messages now use AnimatedList
          Expanded(
            child: AnimatedList(
              key: _listKey,
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              initialItemCount: _chatMessages.length,
              itemBuilder: (context, index, animation) {
                final message = _chatMessages[index];
                return _buildAnimatedMessageItem(message, animation);
              },
            ),
          ),

          // ✅ UI/UX UPDATE: Modern message input bar
          _buildMessageInputBar(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // ✅ UI/UX UPDATE: Using theme colors for consistency
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: theme.unselectedWidgetColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.tv_outlined),
              activeIcon: Icon(Icons.tv),
              label: "Watch"),
          BottomNavigationBarItem(
              icon: Icon(Icons.mosque_outlined),
              activeIcon: Icon(Icons.mosque),
              label: "Prayer"),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: "Chat Box"),
          BottomNavigationBarItem(
              icon: Icon(Icons.apps),
              activeIcon: Icon(Icons.apps),
              label: "Sub Apps"),
        ],
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildAnimatedMessageItem(
      Map<String, String> message, Animation<double> animation) {
    // This wrapper provides the fade and slide animation for new messages
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: _ChatMessageBubble(
          sender: message['sender']!,
          text: message['text']!,
        ),
      ),
    );
  }

  Widget _buildMessageInputBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Ask me anything...",
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.6),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              icon: const Icon(Icons.send_rounded),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(String text, IconData icon) {
    final theme = Theme.of(context);
    return ActionChip(
      avatar: Icon(icon, size: 18, color: theme.colorScheme.primary),
      label: Text(text),
      labelStyle: TextStyle(
          color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
      onPressed: () {
        _addMessage('user', text);
        Future.delayed(const Duration(milliseconds: 500), () {
          _addMessage(
              'ai', 'Sure! Let me get the "$text" information for you.');
        });
      },
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    );
  }
}

// A dedicated widget for the chat bubble UI for cleaner code
class _ChatMessageBubble extends StatelessWidget {
  final String sender;
  final String text;

  const _ChatMessageBubble({required this.sender, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isUser = sender == 'user';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Icon(Icons.smart_toy_rounded,
                  color: colorScheme.primary, size: 20),
            ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isUser ? colorScheme.primary : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
