import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_settings_provider.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ✅ Read data from the provider instead of local state
    final settingsProvider = context.watch<NotificationSettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Settings"),
      ),
      body: settingsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              children: [
                _buildSectionHeader(context, "General Notifications"),
                SwitchListTile(
                  title: const Text("Promotions & Updates"),
                  subtitle:
                      const Text("Receive general announcements and news."),
                  value: settingsProvider.generalNotifications,
                  // ✅ Call the provider's update method
                  onChanged: (val) =>
                      settingsProvider.updateSetting('general', val),
                  secondary: Icon(Icons.campaign_outlined,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader(context, "Prayer Reminders"),
                SwitchListTile(
                    title: const Text("Fajr"),
                    value: settingsProvider.fajr,
                    onChanged: (val) =>
                        settingsProvider.updateSetting('fajr', val)),
                SwitchListTile(
                    title: const Text("Dhuhr"),
                    value: settingsProvider.dhuhr,
                    onChanged: (val) =>
                        settingsProvider.updateSetting('dhuhr', val)),
                SwitchListTile(
                    title: const Text("Asr"),
                    value: settingsProvider.asr,
                    onChanged: (val) =>
                        settingsProvider.updateSetting('asr', val)),
                SwitchListTile(
                    title: const Text("Maghrib"),
                    value: settingsProvider.maghrib,
                    onChanged: (val) =>
                        settingsProvider.updateSetting('maghrib', val)),
                SwitchListTile(
                    title: const Text("Isha"),
                    value: settingsProvider.isha,
                    onChanged: (val) =>
                        settingsProvider.updateSetting('isha', val)),
                const SizedBox(height: 16),
                _buildSectionHeader(context, "Weekly Reminders"),
                SwitchListTile(
                  title: const Text("Khemis (Thursday)"),
                  subtitle: const Text("Reminder for evening Salawat."),
                  value: settingsProvider.khemis,
                  onChanged: (val) =>
                      settingsProvider.updateSetting('khemis', val),
                  secondary: Icon(Icons.event_note_outlined,
                      color: theme.colorScheme.primary),
                ),
              ],
            ),
    );
  }

  // Helper widget for section headers (no changes needed)
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
