// lib/screens/notification_settings_page.dart (New File - Ready to Paste)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // --- State variables for each toggle ---
  bool _isLoading = true;
  bool _generalNotifications = true;
  bool _fajr = true;
  bool _dhuhr = true;
  bool _asr = true;
  bool _maghrib = true;
  bool _isha = true;
  bool _khemis = true; // For Thursday Salawat

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load all saved settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _generalNotifications =
          prefs.getBool('notifications_general_enabled') ?? true;
      _fajr = prefs.getBool('notifications_fajr_enabled') ?? true;
      _dhuhr = prefs.getBool('notifications_dhuhr_enabled') ?? true;
      _asr = prefs.getBool('notifications_asr_enabled') ?? true;
      _maghrib = prefs.getBool('notifications_maghrib_enabled') ?? true;
      _isha = prefs.getBool('notifications_isha_enabled') ?? true;
      _khemis = prefs.getBool('notifications_khemis_enabled') ?? true;
      _isLoading = false;
    });
  }

  // --- Handlers for each switch ---

  Future<void> _onGeneralChanged(bool newValue) async {
    setState(() => _generalNotifications = newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_general_enabled', newValue);

    // Subscribe or unsubscribe from the Firebase topic
    if (newValue) {
      await FirebaseMessaging.instance.subscribeToTopic('all');
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic('all');
    }
  }

  Future<void> _onPrayerChanged(String prayerKey, bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_${prayerKey}_enabled', newValue);
    setState(() {
      switch (prayerKey) {
        case 'fajr':
          _fajr = newValue;
          break;
        case 'dhuhr':
          _dhuhr = newValue;
          break;
        case 'asr':
          _asr = newValue;
          break;
        case 'maghrib':
          _maghrib = newValue;
          break;
        case 'isha':
          _isha = newValue;
          break;
        case 'khemis':
          _khemis = newValue;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Settings"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              children: [
                _buildSectionHeader(context, "General Notifications"),
                SwitchListTile(
                  title: const Text("Promotions & Updates"),
                  subtitle:
                      const Text("Receive general announcements and news."),
                  value: _generalNotifications,
                  onChanged: _onGeneralChanged,
                  secondary: Icon(Icons.campaign_outlined,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader(context, "Prayer Reminders"),
                SwitchListTile(
                    title: const Text("Fajr"),
                    value: _fajr,
                    onChanged: (val) => _onPrayerChanged('fajr', val)),
                SwitchListTile(
                    title: const Text("Dhuhr"),
                    value: _dhuhr,
                    onChanged: (val) => _onPrayerChanged('dhuhr', val)),
                SwitchListTile(
                    title: const Text("Asr"),
                    value: _asr,
                    onChanged: (val) => _onPrayerChanged('asr', val)),
                SwitchListTile(
                    title: const Text("Maghrib"),
                    value: _maghrib,
                    onChanged: (val) => _onPrayerChanged('maghrib', val)),
                SwitchListTile(
                    title: const Text("Isha"),
                    value: _isha,
                    onChanged: (val) => _onPrayerChanged('isha', val)),
                const SizedBox(height: 16),
                _buildSectionHeader(context, "Weekly Reminders"),
                SwitchListTile(
                  title: const Text("Khemis (Thursday)"),
                  subtitle: const Text("Reminder for evening Salawat."),
                  value: _khemis,
                  onChanged: (val) => _onPrayerChanged('khemis', val),
                  secondary: Icon(Icons.event_note_outlined,
                      color: theme.colorScheme.primary),
                ),
              ],
            ),
    );
  }

  // Helper widget for section headers
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
