import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class MediaHubPage extends StatefulWidget {
  const MediaHubPage({super.key});

  @override
  State<MediaHubPage> createState() => _MediaHubPageState();
}

class _MediaHubPageState extends State<MediaHubPage> {
  int _selectedIndex = 1; // 👈 Default = Media tab

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        // already here
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Media Hub",
          style: TextStyle(
            fontSize: size.width * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.cardColor,
        foregroundColor:
            theme.appBarTheme.foregroundColor ?? theme.primaryColorLight,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, size: size.width * 0.065),
            onPressed: () => Navigator.pushNamed(context, "/notifications"),
          ),
          Padding(
            padding: EdgeInsets.only(right: size.width * 0.03),
            child: CircleAvatar(
              radius: size.width * 0.05,
              backgroundImage: const AssetImage("assets/images/profile.jpg"),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: ListView(
            children: [
              SizedBox(height: size.height * 0.02),

              // 🔹 Menu Cards
              _buildMenuCard(
                size: size,
                theme: theme,
                icon: Icons.live_tv_outlined,
                title: "Live Streaming",
                subtitle: "Access real-time broadcasts and events.",
                onTap: () => Navigator.pushNamed(context, '/live'),
              ),
              SizedBox(height: size.height * 0.018),

              _buildMenuCard(
                size: size,
                theme: theme,
                icon: Icons.ondemand_video_outlined,
                title: "YouTube Integration",
                subtitle: "Browse, watch, and manage YouTube content.",
                onTap: () => Navigator.pushNamed(context, '/youtube'),
              ),
              SizedBox(height: size.height * 0.018),

              _buildMenuCard(
                size: size,
                theme: theme,
                icon: Icons.history_toggle_off,
                title: "Recent & Past TV Shows",
                subtitle: "On-demand library with past and recent TV shows.",
                onTap: () => Navigator.pushNamed(context, '/ondemand'),
              ),

              SizedBox(height: size.height * 0.025),
            ],
          ),
        ),
      ),

      // 🔹 Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: theme.unselectedWidgetColor,
        type: BottomNavigationBarType.fixed,
        // backgroundColor: theme.bottomAppBarColor,
        selectedFontSize: size.width * 0.032,
        unselectedFontSize: size.width * 0.03,
        iconSize: size.width * 0.06,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: "Media"),
          BottomNavigationBarItem(icon: Icon(Icons.mosque), label: "Prayer"),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: "ChatBot",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Sub Apps"),
        ],
      ),
    );
  }

  // 🔹 Themed Menu Card
  Widget _buildMenuCard({
    required Size size,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: theme.shadowColor.withOpacity(0.05),
      color: theme.cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.045),
          child: Row(
            children: [
              // Icon in circle
              Container(
                width: size.width * 0.13,
                height: size.width * 0.13,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: size.width * 0.065,
                ),
              ),
              SizedBox(width: size.width * 0.05),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: size.height * 0.005),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: size.width * 0.034,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.7,
                        ),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: theme.iconTheme.color?.withOpacity(0.7),
                size: size.width * 0.07,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
