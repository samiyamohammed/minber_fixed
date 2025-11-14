// lib/screens/permission_screen.dart (NEW FILE)

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // This allows us to re-check permissions when the user returns to the app
    WidgetsBinding.instance.addObserver(this);
    // Request permissions as soon as the screen loads
    _requestPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // This is called when the app's lifecycle state changes (e.g., user returns from settings)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndNavigate();
    }
  }

  Future<void> _checkPermissionsAndNavigate() async {
    final status = await Permission.locationAlways.status;
    if (status.isGranted) {
      // If permission is granted, move to the login screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _requestPermissions() async {
    // 1. Request foreground permission first.
    final foregroundStatus = await Permission.location.request();

    if (foregroundStatus.isGranted) {
      // 2. If foreground is granted, check for background.
      final backgroundStatus = await Permission.locationAlways.status;
      if (!backgroundStatus.isGranted) {
        // 3. If background is not granted, we MUST open settings.
        await openAppSettings();
      } else {
        // If both are already granted, navigate away.
        _checkPermissionsAndNavigate();
      }
    } else {
      // If even foreground is denied, we still need to go to settings.
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Location Permission Required',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'To provide accurate prayer time notifications, this app needs "Allow all the time" location access.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your phone settings should have opened. Please follow these steps:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              const Card(
                elevation: 0,
                color: Color.fromARGB(255, 235, 241, 255),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '1. Tap on "Permissions"\n2. Tap on "Location"\n3. Select "Allow all the time"',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'After granting permission, please return to the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings Again'),
                onPressed: openAppSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
