import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/pwa_install_service.dart';

class PWAInstallButton extends StatefulWidget {
  const PWAInstallButton({super.key});

  @override
  State<PWAInstallButton> createState() => _PWAInstallButtonState();
}

class _PWAInstallButtonState extends State<PWAInstallButton> {
  bool _canInstall = false;
  bool _isDismissed = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkInstallability();
      _checkTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) _checkInstallability();
      });
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  void _checkInstallability() {
    if (!kIsWeb) return;
    final canInstall = PWAInstallService.canInstall();
    final isInstalled = PWAInstallService.isInstalled();
    if (mounted) {
      setState(() {
        _canInstall = canInstall && !isInstalled;
      });
    }
  }

  void _showIOSInstructions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.ios_share, size: 40, color: AppColors.primaryBlue),
            const SizedBox(height: 12),
            const Text(
              'Install Minber TV on iPhone',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _installStep('1', 'Tap the Share button', Icons.ios_share,
                'Tap the share icon at the bottom of Safari'),
            const SizedBox(height: 12),
            _installStep('2', 'Add to Home Screen', Icons.add_box_outlined,
                'Scroll down and tap "Add to Home Screen"'),
            const SizedBox(height: 12),
            _installStep('3', 'Tap Add', Icons.check_circle_outline,
                'Tap "Add" in the top right corner'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Got it!',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _installStep(
      String number, String title, IconData icon, String description) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
              color: AppColors.primaryBlue, shape: BoxShape.circle),
          child: Center(
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        Icon(icon, color: AppColors.primaryBlue, size: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _isDismissed || PWAInstallService.isInstalled()) {
      return const SizedBox.shrink();
    }

    final bool showButton = !PWAInstallService.isInstalled();
    if (!showButton) return const SizedBox.shrink();
    if (!showButton) return const SizedBox.shrink();

    return Positioned(
      bottom: 80,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isDismissed = true),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Colors.grey[700], shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              if (_canInstall) {
                // Android: trigger native install prompt
                PWAInstallService.promptInstall();
              } else {
                // iOS: show manual instructions (only option Apple allows)
                _showIOSInstructions(context);
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.accentBlue]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.install_mobile, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Install App',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
