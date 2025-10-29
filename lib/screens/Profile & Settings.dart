// lib/screens/profile_page.dart (Fully Updated & Ready to Paste)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/user_provider.dart';
import '../models/user_model.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile & Settings"),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          final isLoading = userProvider.isLoading;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: isLoading && user == null
                    ? _buildProfileHeaderSkeleton(context)
                    : user != null
                        ? _buildProfileHeader(context, user)
                        : _buildProfileHeaderError(context),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(context, "Account"),
              _buildProfileTile(
                context,
                icon: Icons.person_outline,
                title: "Edit Profile",
                onTap: () => Navigator.pushNamed(
                  context,
                  '/coming-soon',
                  arguments: 'Edit Profile', // The name of the feature
                ),
              ),
              _buildProfileTile(context,
                  icon: Icons.credit_card_outlined,
                  title: "Manage Subscription",
                  onTap: () => Navigator.pushNamed(context, '/subscription')),
              const SizedBox(height: 16),
              _buildSectionHeader(context, "Preferences"),
              // ✅ THE ONLY CHANGE IS HERE: Updated the onTap function
              _buildProfileTile(context,
                  icon: Icons.notifications_outlined,
                  title: "Notification preferences",
                  onTap: () =>
                      Navigator.pushNamed(context, '/notification-settings')),

              const SizedBox(height: 16),
              _buildSectionHeader(context, "Support"),
              _buildProfileTile(
                context,
                icon: Icons.help_outline,
                title: "Help & Support",
                onTap: () => Navigator.pushNamed(context, '/help-and-support'),
              ),
              _buildProfileTile(context,
                  icon: Icons.info_outline,
                  title: "About Us",
                  onTap: () => Navigator.pushNamed(context, '/about-us')),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutConfirmation(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Log Out"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDER METHODS (Unchanged) ---
  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(children: [
      CircleAvatar(
          radius: 40,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
              style: theme.textTheme.headlineLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold))),
      const SizedBox(height: 12),
      Text(user.username,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(user.email,
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor))
    ]);
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)));
  }

  Widget _buildProfileTile(BuildContext context,
      {required IconData icon,
      required String title,
      Widget? trailing,
      VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.bodyLarge),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
        onTap: onTap);
  }

  Widget _buildProfileHeaderSkeleton(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: Theme.of(context).splashColor,
        highlightColor: Theme.of(context).cardColor,
        child: Column(children: [
          const CircleAvatar(radius: 40, backgroundColor: Colors.white),
          const SizedBox(height: 12),
          Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 8),
          Container(
              width: 200,
              height: 16,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(8)))
        ]));
  }

  Widget _buildProfileHeaderError(BuildContext context) {
    return Column(children: [
      CircleAvatar(
          radius: 40,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          child: Icon(Icons.error_outline,
              size: 30, color: Theme.of(context).colorScheme.onErrorContainer)),
      const SizedBox(height: 12),
      const Text("Could not load profile",
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text("Please check your connection.",
          style: TextStyle(color: Theme.of(context).hintColor))
    ]);
  }
}
