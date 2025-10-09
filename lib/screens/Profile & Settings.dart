// lib/screens/profile_page.dart

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart'; // Make sure this path is correct
import '../models/user_model.dart'; // Make sure this path is correct
import '../core/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    // Use the provider to handle logout logic
    await Provider.of<UserProvider>(context, listen: false).logout();
    
    // Navigate to login screen
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        final isLoading = userProvider.isLoading;
        final logger = Logger();
        logger.d("Profile Page rebuilding. User: ${user?.username}, Loading: $isLoading");

        return Scaffold(
          appBar: AppBar(
            title: const Text("Profile & Settings"),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (isLoading && user == null)
                _buildProfileCardSkeleton()
              else if (user != null)
                _buildProfileCard(context, user) // ✅ PASS THE USER MODEL
              else
                _buildProfileCardError(context),

              // ... rest of your profile page UI ...
              const SizedBox(height: 24),
              _buildSectionHeader(context, "Preferences"),
              _buildProfileTile(
                context,
                icon: Icons.language,
                title: "Language",
                trailing: const Text("English"),
                onTap: () {},
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Log Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ THIS WIDGET IS NOW CORRECTLY TYPED
  Widget _buildProfileCard(BuildContext context, UserModel user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username, // Display username
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email, // Display email
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Other helper widgets remain mostly the same
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall
      ),
    );
  }
   Widget _buildProfileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing:
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  Widget _buildProfileCardSkeleton() {
    return Card( /* ... your skeleton code ... */ );
  }
  Widget _buildProfileCardError(BuildContext context) {
    return Card( /* ... your error card code ... */ );
  }
}