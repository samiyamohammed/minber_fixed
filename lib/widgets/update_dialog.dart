import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';

class UpdateDialog extends StatelessWidget {
  final String localVersion;
  final String storeVersion;

  const UpdateDialog(
      {super.key, required this.localVersion, required this.storeVersion});

  static const String appId = "com.minbertv.minber";

  Future<void> _launchUpdate() async {
    final Uri marketUri = Uri.parse("market://details?id=$appId");
    final Uri webUri =
        Uri.parse("https://play.google.com/store/apps/details?id=$appId");

    // LOGGING VERSIONS
    debugPrint(
        "🔍 MINBER UPDATE: Current($localVersion) -> Newest($storeVersion)");

    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("❌ Update Launch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.system_update_rounded,
                size: 54, color: AppColors.primaryBlue),
            const SizedBox(height: 20),
            const Text("New Update Available",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              "Current: $localVersion  →  Newest: $storeVersion",
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Please update your app to enjoy the latest features and fixes.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("LATER",
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _launchUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("UPDATE",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
