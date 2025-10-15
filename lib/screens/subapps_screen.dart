// lib/screens/subapps_screen.dart (Fully Updated & Ready to Paste)

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

// --- Screen for displaying the web content ---
class EmbeddedWebScreen extends StatefulWidget {
  final String url;
  final String appName;

  const EmbeddedWebScreen(
      {super.key, required this.url, required this.appName});

  @override
  State<EmbeddedWebScreen> createState() => _EmbeddedWebScreenState();
}

class _EmbeddedWebScreenState extends State<EmbeddedWebScreen> {
  late final WebViewController _controller;
  double _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) =>
              setState(() => _loadingProgress = progress / 100),
          onPageStarted: (String url) => setState(() => _loadingProgress = 0),
          onPageFinished: (String url) => setState(() => _loadingProgress = 0),
          onWebResourceError: (WebResourceError error) {
            Fluttertoast.showToast(
                msg: "Error loading ${widget.appName}: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: _loadingProgress > 0 && _loadingProgress < 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: Colors.transparent),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _controller.reload(),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}

// --- KiriyogdeyraPage Widget ---
class KiriyogdeyraPage extends StatefulWidget {
  const KiriyogdeyraPage({super.key});
  @override
  State<KiriyogdeyraPage> createState() => _KiriyogdeyraPageState();
}

class _KiriyogdeyraPageState extends State<KiriyogdeyraPage> {
  int _selectedIndex = 4;
  final List<Map<String, dynamic>> _featuredApps = [
    {
      'name': 'Kirbgebeya',
      'description': 'Shop online and find great deals',
      'image': 'assets/images/kirbgebeya.png',
      'url': 'https://kirbgebeya.com/'
    },
    {
      'name': 'almathurat',
      'description': 'Recite Morning and Evening Adhkar',
      'image': 'assets/images/almathurat.jpg',
      'url': 'https://Skylinkict.com/almathurat'
    },
    {
      'name': 'Alfurqan App',
      'description': 'Read, listen, and understand the Quran',
      'image': 'assets/images/alfuqan.jpg',
      // ✅ UPDATE: Added the URL to open in the webview
      'url': 'https://skylinkict.com/alfurqan'
    },
    {
      'name': 'Besirah',
      'description': 'Explore historical and religious content',
      'image': 'assets/images/besira.jpg'
      // No URL, will show a toast message
    },
  ];

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
        routeName = '/chatbot';
        break;
      case 4:
        break;
    }
    if (routeName.isNotEmpty) {
      Navigator.pushReplacementNamed(context, routeName);
    }
  }

  void _openApp(Map<String, dynamic> app) {
    final url = app['url'] as String?;
    if (url != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  EmbeddedWebScreen(url: url, appName: app['name'])));
    } else {
      Fluttertoast.showToast(msg: "Opening ${app['name']}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Sub Apps"), centerTitle: true),
      body: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _featuredApps.length,
          itemBuilder: (context, index) {
            final app = _featuredApps[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildAppCard(theme, app),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildAppCard(ThemeData theme, Map<String, dynamic> app) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _openApp(app),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(app['image'],
                    width: 60, height: 60, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app['name'],
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(app['description'],
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.hintColor)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: theme.hintColor),
            ],
          ),
        ),
      ),
    );
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
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.apps),
            label: "Sub Apps"),
      ],
    );
  }
}
