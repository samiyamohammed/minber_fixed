import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:minber_super_app_new_fixed/screens/chat_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  int _selectedIndex = 3;

  // SharedPreferences instance and keys
  late SharedPreferences _prefs;
  static const String _chatHistoryKey = 'chat_history';
  // ⭐ 1. New state variables for caching ⭐
  static const String _chatCacheKey = 'chat_cache';
  final Map<String, String> _chatCache = {};

  final List<String> _faqQuestions = [
    "When is the next prayer time?",
    "How do I perform Wudu correctly?",
    "What breaks fasting in Ramadan?",
    "Can I pray sitting if I'm sick?",
    "How do I calculate Zakat?",
    "What is Tahajjud prayer?",
  ];

  @override
  void initState() {
    super.initState();
    _initSharedPreferencesAndLoadData();
  }

  // ⭐ 2. Updated init method to load BOTH history and cache ⭐
  Future<void> _initSharedPreferencesAndLoadData() async {
    _prefs = await SharedPreferences.getInstance();
    _loadChatCache(); // Load cache first
    _loadChatHistory(); // Then load history
  }

  void _loadChatHistory() {
    final String? historyString = _prefs.getString(_chatHistoryKey);
    if (historyString != null && historyString.isNotEmpty) {
      try {
        final List<dynamic> decodedHistory = jsonDecode(historyString);
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(decodedHistory
                .map((item) => Map<String, String>.from(item))
                .toList());
          });
        }
        _scrollToBottom();
      } catch (e) {
        print("Error loading chat history: $e");
        _setDefaultWelcomeMessage();
      }
    } else {
      _setDefaultWelcomeMessage();
    }
  }

  void _setDefaultWelcomeMessage() {
    if (mounted && _messages.isEmpty) {
      setState(() {
        _messages.add(
            {"sender": "bot", "text": "Hello! Ask me anything about Islam."});
      });
    }
  }

  // ⭐ 3. New method to load the cache from SharedPreferences ⭐
  void _loadChatCache() {
    final String? cacheString = _prefs.getString(_chatCacheKey);
    if (cacheString != null && cacheString.isNotEmpty) {
      try {
        final Map<String, dynamic> decodedCache = jsonDecode(cacheString);
        _chatCache.addAll(decodedCache.cast<String, String>());
        print(
            "Chat cache loaded successfully with ${_chatCache.length} items.");
      } catch (e) {
        print("Error loading chat cache: $e");
      }
    }
  }

  Future<void> _saveChatHistory() async {
    final String encodedHistory = jsonEncode(_messages);
    await _prefs.setString(_chatHistoryKey, encodedHistory);
  }

  // ⭐ 4. New method to save the cache to SharedPreferences ⭐
  Future<void> _saveChatCache() async {
    final String encodedCache = jsonEncode(_chatCache);
    await _prefs.setString(_chatCacheKey, encodedCache);
    print("Chat cache saved.");
  }

  void _onHistoryCleared() {
    if (mounted) {
      setState(() {
        _messages.clear();
        _messages.add(
            {"sender": "bot", "text": "Hello! Ask me anything about Islam."});
      });
    }
    _scrollToBottom();
  }

  Future<void> _sendMessage(String message) async {
    final String trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": trimmedMessage});
      _controller.clear();
      _isTyping = true;
    });

    _saveChatHistory();
    _scrollToBottom();

    // ⭐ 5. Caching Logic Implementation ⭐
    // Check cache before making a network call
    if (_chatCache.containsKey(trimmedMessage)) {
      final cachedResponse = _chatCache[trimmedMessage]!;
      print("Cache HIT for: '$trimmedMessage'");
      setState(() {
        _messages.add({"sender": "bot", "text": cachedResponse});
        _isTyping = false;
      });
      _saveChatHistory(); // Save bot's cached response to history
      _scrollToBottom();
      return; // Stop execution here to avoid network call
    }

    print("Cache MISS for: '$trimmedMessage'. Fetching from API...");
    // If not in cache, proceed with API call
    try {
      final response = await http.post(
        Uri.parse("http://msa.merkuz.com:3636/gemini/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": trimmedMessage}),
      );

      String reply;
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        reply = data["response"] ?? "No response from AI.";

        // ⭐ 6. Save new response to cache ⭐
        _chatCache[trimmedMessage] = reply;
        await _saveChatCache();
      } else {
        reply =
            "Error ${response.statusCode}: Failed to get a proper response from the server.";
      }
      if (mounted) {
        setState(() {
          _messages.add({"sender": "bot", "text": reply});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            "sender": "bot",
            "text":
                "Sorry, I couldn’t connect to the server. Please check your internet and try again."
          });
        });
      }
      print("Network/API Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
      _saveChatHistory();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    String routeName = '';
    switch (index) {
      case 0:
        routeName = '/home';
        break;
      case 1:
        routeName = '/media';
        break;
      case 2:
        routeName = '/prayer';
        break;
      case 3:
        break; // Already on Chat Bot page
      case 4:
        routeName = '/subapps';
        break;
    }
    if (routeName.isNotEmpty) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  BottomNavigationBar _buildBottomNavBar(ThemeData theme) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: theme.colorScheme.primary,
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
            label: "Media"),
        BottomNavigationBarItem(
            icon: Icon(Icons.mosque_outlined),
            activeIcon: Icon(Icons.mosque),
            label: "Prayer"),
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: "Chat Bot"),
        BottomNavigationBarItem(
            icon: Icon(Icons.apps),
            activeIcon: Icon(Icons.apps),
            label: "Sub Apps"),
      ],
    );
  }

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
        title: const Text("Ask Islam Chatbot"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "View Chat History",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatHistoryScreen(
                    initialHistory: List.from(_messages),
                    onHistoryCleared: _onHistoryCleared,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surface.withOpacity(0.7)
                  : Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _faqQuestions.map((question) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      label: Text(
                        question,
                        style: TextStyle(
                          color: isDark ? Colors.white : theme.primaryColor,
                          fontSize: 13,
                        ),
                      ),
                      backgroundColor: isDark
                          ? Colors.white10
                          : theme.primaryColor.withOpacity(0.1),
                      onPressed:
                          _isTyping ? null : () => _sendMessage(question),
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "AI is typing...",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }
                final message = _messages[index];
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
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: theme.scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      enabled: !_isTyping,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: "Ask something...",
                        hintStyle: TextStyle(
                          color: theme.hintColor.withOpacity(0.6),
                        ),
                        filled: true,
                        fillColor:
                            isDark ? Colors.white10 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: theme.primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isTyping
                          ? null
                          : () => _sendMessage(_controller.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }
}
