import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Make sure this is added to pubspec.yaml

// --- Screen for displaying the web content ---
// This screen will be navigated to when Kirbgebeya is tapped.
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
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
      ..setBackgroundColor(const Color(0x00000000)) // Transparent background
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // This callback is part of NavigationDelegate
            debugPrint('Page started loading: $url');
            // You can show a loading indicator here if needed.
          },
          onProgress: (int progress) {
            // Update loading bar if you have one
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageFinished: (String url) {
            // This callback is part of NavigationDelegate
            debugPrint('Page finished loading: $url');
            // You can hide the loading indicator here.
          },
          onWebResourceError: (WebResourceError error) {
            // Handle errors from the web page loading
            debugPrint('Page resource error: ${error.description}');
            Fluttertoast.showToast(
              msg: "Error loading ${widget.appName}: ${error.description}",
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            // This allows you to control which URLs the WebView can navigate to.
            // For now, we allow all navigations.
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url)); // Load the specified URL
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.appName, // Dynamically set the AppBar title
          style: TextStyle(
            fontSize: size.width * 0.05,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.colorScheme.onBackground,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onBackground),
          onPressed: () =>
              Navigator.pop(context), // Navigate back to the previous screen
        ),
      ),
      body: WebViewWidget(
        controller: _controller,
      ), // Display the WebView content
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
  int _selectedIndex = 4; // Default to the Sub Apps tab

  final List<Map<String, dynamic>> _featuredApps = [
    // Kirbgebeya moved to the first position
    {
      'name': 'Kirbgebeya',
      'description': 'Shop online and find great deals',
      'image': 'assets/images/kirbgebeya.png',
      'url': 'https://kirbgebeya.com/', // URL for Kirbgebeya
    },
    {
      'name': 'Besirah',
      'description': 'Explore historical and religious content on demand.',
      'image': 'assets/images/besira.jpg',
      // No URL provided, so it will trigger a toast or internal navigation.
    },
    {
      'name': 'Alfurqan App',
      'description': 'Read, listen, and understand the Quran',
      'image': 'assets/images/alfuqan.jpg',
      // No URL provided.
    },
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index)
      return; // Do nothing if already on the same tab

    setState(() => _selectedIndex = index); // Update the selected tab

    // Navigate to the corresponding route based on the selected index
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
        Navigator.pushReplacementNamed(context, '/Chat Bot');
        break;
      case 4:
        // Currently on KiriyogdeyraPage (Sub Apps), so no navigation needed if tapped again.
        // If navigating from another page to this one, this is the correct route.
        Navigator.pushReplacementNamed(context, '/subapps');
        break;
    }
  }

  /// Handles the action when an app card is tapped.
  void _openApp(Map<String, dynamic> app) {
    final appName = app['name'];
    final appUrl = app['url']; // Get the URL if it exists

    if (appName == 'Kirbgebeya' && appUrl != null && appUrl is String) {
      // If it's Kirbgebeya and has a URL, navigate to the embedded web view screen.
      Navigator.push(
        context,
        MaterialPageRoute(
          // Pass the URL and app name to the embedded screen.
          builder: (context) =>
              EmbeddedWebScreen(url: appUrl, appName: appName),
        ),
      );
    } else if (appUrl != null && appUrl is String) {
      // If it's any other app with a URL, launch it in the external browser.
      _launchURL(appUrl, appName);
    } else {
      // If no URL is provided, show a toast message.
      // You can add internal navigation logic here for apps that are part of your project.
      Fluttertoast.showToast(msg: "Opening $appName");
      // Example of internal navigation:
      // if (appName == 'Besirah') {
      //   Navigator.pushNamed(context, '/besirah_details');
      // }
    }
  }

  /// Launches a URL in the external browser.
  Future<void> _launchURL(String url, String appName) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        // Use LaunchMode.externalApplication to open in the system's browser.
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Fluttertoast.showToast(msg: "Opening $appName in browser");
      } else {
        Fluttertoast.showToast(
          msg: "Could not open $appName. Please check the URL.",
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error opening $appName: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          "Sub Apps",
          style: TextStyle(
            fontSize: size.width * 0.05,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.colorScheme.onBackground,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: theme.iconTheme.color,
              size: size.width * 0.06,
            ),
            onPressed: () => Fluttertoast.showToast(
              msg: "Search apps",
            ), // Placeholder for search functionality
          ),
          Padding(
            padding: EdgeInsets.only(right: size.width * 0.03),
            child: InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                "/profile",
              ), // Navigate to profile
              borderRadius: BorderRadius.circular(50), // Make tap area circular
              child: CircleAvatar(
                radius: size.width * 0.05,
                backgroundImage: const AssetImage(
                  "assets/images/profile.jpg",
                ), // Your profile image
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
            ListView.separated(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling for ListView inside SingleChildScrollView
              itemCount: _featuredApps.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: size.height * 0.03), // Spacing between cards
              itemBuilder: (context, index) {
                final app = _featuredApps[index];
                return GestureDetector(
                  onTap: () => _openApp(app), // Make the entire card tappable
                  child: Container(
                    padding: EdgeInsets.all(size.width * 0.04),
                    decoration: BoxDecoration(
                      color: theme.cardColor, // Use theme's card color
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners for the card
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(
                            0.1,
                          ), // Subtle shadow
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Vertically align items in the row
                      children: [
                        // App Icon
                        Container(
                          width: size.width * 0.15,
                          height: size.width * 0.15,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(app['image']), // Load app image
                              fit: BoxFit
                                  .cover, // Ensure image covers the container
                            ),
                          ),
                        ),
                        SizedBox(
                          width: size.width * 0.04,
                        ), // Spacing between icon and text
                        // App Info (Name and Description)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app['name'],
                                style: TextStyle(
                                  fontSize: size.width * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onBackground,
                                ),
                              ),
                              SizedBox(
                                height: size.height * 0.005,
                              ), // Small spacing between name and description
                              Text(
                                app['description'],
                                style: TextStyle(
                                  fontSize: size.width * 0.035,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(
                                        0.7,
                                      ), // Slightly dimmed description
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Forward Arrow Icon - indicates interactivity
                        Icon(
                          Icons.arrow_forward_ios,
                          color: theme
                              .colorScheme
                              .primary, // Use theme's primary color
                          size: size.width * 0.05,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Set the currently selected item
        onTap: _onItemTapped, // Handler for tap events
        selectedItemColor: theme.colorScheme.primary, // Color for selected item
        unselectedItemColor: theme.textTheme.bodyMedium?.color?.withOpacity(
          0.7,
        ), // Color for unselected items
        type: BottomNavigationBarType
            .fixed, // Use fixed type for consistent appearance
        selectedFontSize: size.width * 0.03,
        unselectedFontSize: size.width * 0.03,
        iconSize: size.width * 0.06,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: "Media"),
          BottomNavigationBarItem(icon: Icon(Icons.mosque), label: "Prayer"),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble), // Active state icon
            label: "Chat Box",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Sub Apps"),
        ],
      ),
    );
  }
}
