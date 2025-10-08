import 'package:flutter/material.dart';
import 'package:minber_super_app_new_fixed/core/theme_notifier.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../main.dart' as main;
import '../providers/user_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isLoggedIn = userProvider.user != null;

    return Drawer(
      child: ListView(
        // Changed from Column to a single ListView
        padding: EdgeInsets.zero,
        children: [
          // This Consumer rebuilds the header when user data changes
          Consumer<UserProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.user == null) {
                return _buildLoadingHeader();
              } else if (isLoggedIn) {
                return _buildLoggedInHeader(context, theme, provider);
              } else {
                return _buildLoggedOutHeader(context, theme);
              }
            },
          ),

          _buildDrawerItem(
            icon: Icons.home_outlined,
            text: 'Home',
            onTap: () => Navigator.pop(context), // Just close the drawer
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
            icon: Icons.notifications_none,
            text: 'Notifications',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, "/notifications");
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings_outlined,
            text: 'Settings',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(indent: 16, endIndent: 16),

          // --- FIX: DARK THEME TOGGLE IS NOW HERE ---
          ValueListenableBuilder<ThemeMode>(
            valueListenable: main.themeNotifier,
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
                  main.themeNotifier.value = newMode;
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

  // --- DRAWER HEADER WIDGETS ---

  Widget _buildLoggedInHeader(
      BuildContext context, ThemeData theme, UserProvider provider) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: AppColors.primary,
        image: DecorationImage(
          image: const AssetImage(
              "assets/images/drawer_bg.png"), // Add a subtle pattern
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.primary.withOpacity(0.3),
            BlendMode.dstATop,
          ),
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
              backgroundColor: Colors.white,
              child: Text(
                provider.user!.username.isNotEmpty
                    ? provider.user!.username[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Hello, ${provider.user!.username}",
              style: theme.textTheme.titleLarge?.copyWith(
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

  Widget _buildLoggedOutHeader(BuildContext context, ThemeData theme) {
    return DrawerHeader(
      decoration: BoxDecoration(color: theme.cardColor),
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
            Text("Welcome", style: theme.textTheme.titleLarge),
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

  // --- DRAWER ITEM HELPER ---

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

  // --- LOGOUT CONFIRMATION ---

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
                Provider.of<UserProvider>(dialogContext, listen: false)
                    .logout();
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        );
      },
    );
  }
}
