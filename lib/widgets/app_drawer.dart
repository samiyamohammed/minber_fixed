// lib/widgets/app_drawer.dart (Fully Corrected & Ready to Paste)

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import '../core/theme_notifier.dart';
import '../core/app_colors.dart';
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
    final userProvider = Provider.of<UserProvider>(context);
    final isLoggedIn = userProvider.user != null;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
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
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            text: 'Settings',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            icon: Icons.notifications_outlined,
            text: 'Notifications',
            onTap: () {
              Navigator.pushNamed(context, "/notifications");
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              return SwitchListTile(
                title: const Text('Dark Mode'),
                secondary: Icon(
                  currentMode == ThemeMode.dark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                value: currentMode == ThemeMode.dark,
                onChanged: (isDark) {
                  final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
                  themeNotifier.value = newMode;
                  saveThemePreference(newMode);
                },
              );
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          _buildDrawerItem(
            icon: Icons.info_outline,
            text: 'About Us',
            onTap: () {
              Navigator.pop(context);
            },
          ),
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

  // --- WIDGET BUILDER METHODS ---

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

  // --- THIS IS THE CORRECTED FUNCTION ---
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
              onPressed: () async {
                // Wait for the logout process to complete
                await Provider.of<UserProvider>(context, listen: false)
                    .logout();

                // Then, perform the robust navigation
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
