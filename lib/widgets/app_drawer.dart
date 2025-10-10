// lib/widgets/app_drawer.dart (Fully Updated & Ready to Paste)

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import '../core/theme_notifier.dart';
import '../core/app_colors.dart';
import '../providers/user_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // A simple hashing function to assign a consistent, pleasant color to a user based on their name.
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
    // Get the current route name to highlight the active item
    final String? currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      // Use the theme's background color for the drawer itself
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          // --- DRAWER ITEMS ---
          _buildDrawerItem(
            context: context,
            icon: Icons.home_outlined,
            text: 'Home',
            onTap: () {
              Navigator.pop(context); // Close drawer
              // If not already on home, navigate home. This prevents pushing multiple home screens.
              if (currentRoute != '/home') {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false);
              }
            },
            routeName: '/home',
            currentRoute: currentRoute,
          ),
          if (isLoggedIn)
            _buildDrawerItem(
              context: context,
              icon: Icons.person_outline,
              text: 'Profile',
              onTap: () {
                Navigator.pop(context);
                if (currentRoute != '/profile') {
                  Navigator.pushNamed(context, "/profile");
                }
              },
              routeName: '/profile',
              currentRoute: currentRoute,
            ),
          _buildDrawerItem(
            context: context,
            icon: Icons.notifications_outlined,
            text: 'Notifications',
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != '/notifications') {
                Navigator.pushNamed(context, "/notifications");
              }
            },
            routeName: '/notifications',
            currentRoute: currentRoute,
          ),
          const Divider(indent: 16, endIndent: 16),
          // --- THEME SWITCH ---
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              return SwitchListTile(
                title: const Text('Dark Mode'),
                secondary: Icon(
                  currentMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                value: currentMode == ThemeMode.dark,
                onChanged: (isDark) {
                  final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
                  themeNotifier.value = newMode;
                  saveThemePreference(newMode);
                },
                activeColor: AppColors.accentBlue,
              );
            },
          ),
          const Divider(indent: 16, endIndent: 16),
          // --- LOGOUT BUTTON ---
          if (isLoggedIn)
            _buildDrawerItem(
              context: context,
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
      // ✅ UI/UX UPDATE: Professional gradient using brand colors
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
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
    );
  }

  Widget _buildLoggedOutHeader(BuildContext context) {
    // ✅ UI/UX UPDATE: Cleaner, more inviting header with a clear call-to-action
    return DrawerHeader(
      decoration:
          BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Welcome to Minber TV",
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Sign in to access your profile and subscriptions.",
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
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
    );
  }

  Widget _buildLoadingHeader() {
    // ✅ UI/UX UPDATE: Consistent branding in the loading state
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
    // ✅ UI/UX UPDATE: Highlights the currently active page in the drawer
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
        // ✅ UI/UX UPDATE: Dialog now matches the app's modern, rounded aesthetic
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
