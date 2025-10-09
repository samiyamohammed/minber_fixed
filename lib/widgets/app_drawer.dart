// lib/widgets/app_drawer.dart

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:minber_super_app_new_fixed/core/theme_notifier.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../main.dart' as main;
import '../providers/user_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Color _getUserColor(String username) {
    final List<Color> userColors = [
      Colors.red.shade400,
      Colors.green.shade400,
      Colors.blue.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
    ];
    return userColors[username.hashCode.abs() % userColors.length];
  }

  @override
  Widget build(BuildContext context) {
    // ✅ This is now the single source of truth for the user's login state
    final userProvider = Provider.of<UserProvider>(context);
    final isLoggedIn = userProvider.user != null;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // This Consumer rebuilds ONLY the header when user data changes
          Consumer<UserProvider>(
            builder: (context, provider, child) {
              final logger = Logger();
              logger.d(
                  "Drawer Header rebuilding. User: ${provider.user?.username}");

              if (provider.isLoading && provider.user == null) {
                return _buildLoadingHeader();
              } else if (provider.user != null) {
                return _buildLoggedInHeader(context, provider);
              } else {
                return _buildLoggedOutHeader(context);
              }
            },
          ),

          _buildDrawerItem(
            icon: Icons.home_outlined,
            text: 'Home',
            onTap: () => Navigator.pop(context),
          ),
          if (isLoggedIn)
            _buildDrawerItem(
              icon: Icons.person_outline,
              text: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/profile");
              },
            ),
          // ... rest of your drawer items
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            text: 'Settings',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          if (isLoggedIn)
            _buildDrawerItem(
              icon: Icons.logout,
              text: 'Logout',
              onTap: () => _showLogoutConfirmation(context),
            ),
        ],
      ),
    );
  }

  Widget _buildLoggedInHeader(BuildContext context, UserProvider provider) {
    final user = provider.user!;
    final userColor = _getUserColor(user.username);
    final initial =
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?';

    return DrawerHeader(
      decoration: BoxDecoration(color: AppColors.primary),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/profile");
              },
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: userColor,
                child: Text(
                  initial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Hello, ${user.username}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const Text(
              "Welcome Back!",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // Other helper methods (_buildLoggedOutHeader, etc.) remain the same
  Widget _buildLoggedOutHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 12),
            Text("Welcome", style: Theme.of(context).textTheme.titleLarge),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/login");
              },
              child: Text(
                "Tap to sign in or register",
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(color: AppColors.primary),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              child: const Text("Logout"),
              onPressed: () {
                // Use the provider to log out
                Provider.of<UserProvider>(dialogContext, listen: false)
                    .logout();
                Navigator.of(dialogContext).pop(); // Close the dialog
                Navigator.of(context)
                    .pushReplacementNamed('/login'); // Go to login page
              },
            ),
          ],
        );
      },
    );
  }
}
