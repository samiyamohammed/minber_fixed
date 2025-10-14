// lib/screens/help_and_support_page.dart (New File - Ready to Paste)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpAndSupportPage extends StatefulWidget {
  const HelpAndSupportPage({super.key});

  @override
  State<HelpAndSupportPage> createState() => _HelpAndSupportPageState();
}

class _HelpAndSupportPageState extends State<HelpAndSupportPage> {
  PackageInfo _packageInfo = PackageInfo(
      appName: 'Unknown',
      packageName: 'Unknown',
      version: 'Unknown',
      buildNumber: 'Unknown');

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _packageInfo = info);
  }

  // Helper to launch the email client
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@minbertv.com', // Your support email
      queryParameters: {
        'subject':
            'Minber Super App Support Request (v${_packageInfo.version})',
        'body': '''
-----------------------------
Please describe your issue above this line.
App Version: ${_packageInfo.version} (${_packageInfo.buildNumber})
Device OS: ${Theme.of(context).platform}
-----------------------------
'''
      },
    );

    if (!await launchUrl(emailLaunchUri)) {
      Fluttertoast.showToast(msg: 'Could not open email client');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Section 1: FAQs ---
          _buildSectionHeader(theme, "Frequently Asked Questions"),
          const SizedBox(height: 8),
          _buildFaqTile(
            question: "How do I reset my password?",
            answer:
                "If you've forgotten your password, go to the login screen and tap on the 'Forgot Password?' link. You will receive an email with instructions to create a new one.",
          ),
          _buildFaqTile(
            question: "Why is the live stream not working?",
            answer:
                "First, please check your internet connection. If the issue persists, the stream may be temporarily down for maintenance. Try again in a few minutes.",
          ),
          _buildFaqTile(
            question: "How do I manage my subscription?",
            answer:
                "You can manage your Halal Premium subscription by navigating to Profile & Settings > Manage Subscription. From there, you can view your plan details or choose to upgrade.",
          ),
          _buildFaqTile(
            question: "How does the Qibla compass work?",
            answer:
                "The Qibla compass uses your device's location and magnetometer sensors. For best results, ensure location services are enabled and hold your phone flat, away from metal objects.",
          ),
          const SizedBox(height: 24),

          // --- Section 2: Contact Us ---
          _buildSectionHeader(theme, "Contact Us"),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: theme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                      "If you can't find the answer you're looking for, please don't hesitate to reach out to our support team."),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _launchEmail,
                      icon: const Icon(Icons.email_outlined),
                      label: const Text("Email Support"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- Section 3: App Information ---
          _buildSectionHeader(theme, "App Information"),
          const SizedBox(height: 8),
          ListTile(
            title: const Text("App Version"),
            subtitle:
                Text("${_packageInfo.version} (${_packageInfo.buildNumber})"),
            trailing: IconButton(
              icon: const Icon(Icons.copy_outlined, size: 20),
              onPressed: () {
                final info =
                    "Version: ${_packageInfo.version} (${_packageInfo.buildNumber})";
                Clipboard.setData(ClipboardData(text: info));
                Fluttertoast.showToast(msg: "App info copied");
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  // Using ExpansionTile for the accordion effect
  Widget _buildFaqTile({required String question, required String answer}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title:
            Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(answer,
              style:
                  TextStyle(color: Theme.of(context).hintColor, height: 1.5)),
        ],
      ),
    );
  }
}
