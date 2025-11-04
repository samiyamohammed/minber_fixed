// lib/screens/subapps_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';
import './coming_soon_page.dart';

/// ---------------------------------------------------------------
///  Embedded web view (unchanged – works in light & dark)
/// ---------------------------------------------------------------
class EmbeddedWebScreen extends StatefulWidget {
  final String url;
  final String appName;

  const EmbeddedWebScreen({
    super.key,
    required this.url,
    required this.appName,
  });

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
          onPageStarted: (_) => setState(() => _loadingProgress = 0),
          onPageFinished: (_) => setState(() => _loadingProgress = 0),
          onWebResourceError: (error) {
            Fluttertoast.showToast(
              msg: "Error loading ${widget.appName}: ${error.description}",
            );
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
                child: LinearProgressIndicator(value: _loadingProgress),
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

/// ---------------------------------------------------------------
///  Sub-Apps list screen (now fully dark-mode aware and consistent)
/// ---------------------------------------------------------------
class KiriyogdeyraPage extends StatefulWidget {
  const KiriyogdeyraPage({super.key});

  @override
  State<KiriyogdeyraPage> createState() => _KiriyogdeyraPageState();
}

class _KiriyogdeyraPageState extends State<KiriyogdeyraPage> {
  int _selectedIndex = 4; // Sub-Apps tab

  final List<Map<String, dynamic>> _featuredApps = [
    {
      'name': 'Kirbgebeya',
      'description': 'Shop online and find great deals',
      'image': 'assets/images/kirbgebeya.png',
      'url': 'https://kirbgebeya.com/',
    },
    {
      'name': 'almathurat',
      'description': 'Recite Morning and Evening Adhkar',
      'image': 'assets/images/almathurat.jpg',
      'url': 'https://Skylinkict.com/almathurat',
    },
    {
      'name': 'Alfurqan App',
      'description': 'Read, listen, and understand the Quran',
      'image': 'assets/images/alfuqan.jpg',
      'url': 'https://skylinkict.com/alfurqan',
    },
    {
      'name': 'Besirah',
      'description': 'Explore historical and religious content',
      'image': 'assets/images/besira.jpg',
    },
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    const routes = [
      '/home',
      '/media',
      '/prayer',
      '/chatbot',
      null, // stay on current page
    ];
    final route = routes[index];
    if (route != null) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  void _openApp(Map<String, dynamic> app) {
    final url = app['url'] as String?;
    if (url != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmbeddedWebScreen(url: url, appName: app['name']),
        ),
      );
    } else {
      Navigator.pushNamed(
        context,
        '/coming-soon',
        arguments: app['name'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // UPDATED: Set background to Colors.white in light mode to match AppBar
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Sub Apps',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? Colors.transparent : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.blue),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      body: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          itemCount: _featuredApps.length,
          itemBuilder: (context, index) {
            final app = _featuredApps[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 350),
              child: SlideAnimation(
                verticalOffset: 40,
                child: FadeInAnimation(
                  child: _buildAppCard(theme, isDark, app),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  Widget _buildAppCard(ThemeData theme, bool isDark, Map<String, dynamic> app) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    // In light mode, the cards are white. To make them visible on a white
    // background, we rely on the shadow from elevation. Let's make sure
    // the card has a subtle border or slightly different color if needed.
    // Or we use a very light grey for the background.
    // Sticking with white cards on a slightly off-white bg is usually best.
    // Let's change the light bg to a very faint grey for better card visibility.
    // Reverting to `Colors.grey[50]` for a subtle difference.
    // The user wants an EXACT match. So we'll use a subtle border on the card
    // in light mode.

    return Card(
      elevation: isDark ? 1.5 : 2,
      // For light mode on a white background, a very faint border can help.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark
            ? BorderSide.none
            : BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      color: cardColor, // This will be Colors.white in light mode
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openApp(app),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  app['image'],
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app['name'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      app['description'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white70 : Colors.grey[700],
                        fontSize: 14.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.hintColor,
                size: 20,
              ),
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
      backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.tv_outlined),
          activeIcon: Icon(Icons.tv),
          label: "Media",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.mosque_outlined),
          activeIcon: Icon(Icons.mosque),
          label: "Prayer",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: "ChatBot",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.apps_outlined),
          activeIcon: Icon(Icons.apps),
          label: "Sub Apps",
        ),
      ],
    );
  }
}
