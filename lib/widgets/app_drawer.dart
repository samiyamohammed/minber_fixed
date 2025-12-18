// lib/widgets/app_drawer.dart (FINAL VERSION WITH OVERFLOW FIX)

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:minber/providers/notification_provider.dart';

import '../core/theme_notifier.dart';
import '../core/app_colors.dart';
import '../providers/user_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Color _getUserColor(String username) {
    final List<Color> userColors = [
      Colors.red.shade400,
      Colors.green.shade400,
      const Color(0xFF29B6F6), // Using our brand's accent blue
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
    final String? currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header Section
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

          // Home Item
          _buildDrawerItem(
            context: context,
            icon: Icons.home_outlined,
            text: 'Home',
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != '/home') {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false);
              }
            },
            routeName: '/home',
            currentRoute: currentRoute,
          ),

          // Profile Item (Only if logged in)
          if (isLoggedIn)
            _buildDrawerItem(
              context: context,
              icon: Icons.person_outline,
              text: 'Profile and Settings',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != '/profile') {
                  Navigator.pushNamed(context, "/profile");
                }
              },
              routeName: '/profile',
              currentRoute: currentRoute,
            ),

          // Notifications Item
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              final bool isSelected = currentRoute == '/notifications';
              return ListTile(
                leading: Badge(
                  label: Text(provider.unreadCount.toString()),
                  isLabelVisible: provider.unreadCount > 0,
                  child: Icon(
                    Icons.notifications_outlined,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                title: Text(
                  'Notifications',
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (currentRoute != '/notifications') {
                    Navigator.pushNamed(context, "/notifications");
                  }
                },
                selected: isSelected,
                selectedTileColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
              );
            },
          ),
          const Divider(indent: 16, endIndent: 16),

          // Dark Mode Switch
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              final isDarkMode = currentMode == ThemeMode.dark ||
                  (currentMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness ==
                          Brightness.dark);

              return SwitchListTile(
                title: const Text('Dark Mode'),
                secondary: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                value: isDarkMode,
                onChanged: (isNowDark) {
                  final newMode = isNowDark ? ThemeMode.dark : ThemeMode.light;
                  themeNotifier.value = newMode;
                  saveThemePreference(newMode);
                },
                activeColor: AppColors.accentBlue,
              );
            },
          ),
          const Divider(indent: 16, endIndent: 16),

          // Logout Item (Only if logged in)
          if (isLoggedIn)
            _buildDrawerItem(
              context: context,
              icon: Icons.logout,
              text: 'Logout',
              onTap: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      // --- ✅ FIX: SingleChildScrollView added here too for safety ---
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
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
              const SizedBox(height: 12),
              Text(
                user.username,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 2.0, color: Colors.black26)]),
              ),
              const Text(
                "Welcome Back!",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedOutHeader(BuildContext context) {
    return DrawerHeader(
      decoration:
          BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      // --- ✅ FIX: SingleChildScrollView fixes the "Bottom Overflowed" error ---
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Prevents taking up infinite space
          children: [
            Text("Welcome to Minber TV",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Sign in to access your profile and subscriptions.",
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/login");
              },
              child: const Text("Sign In or Register"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingHeader() {
    return const DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    String? routeName,
    String? currentRoute,
  }) {
    final bool isSelected = routeName != null && routeName == currentRoute;

    return ListTile(
      leading: Icon(icon,
          color: isSelected ? Theme.of(context).colorScheme.primary : null),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Logout"),
              onPressed: () async {
                await Provider.of<UserProvider>(context, listen: false)
                    .logout();

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
