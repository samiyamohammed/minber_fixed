// lib/screens/about_us_page.dart (Fully Updated & Ready to Paste)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // ✅ UI/UX UPDATE: For social media icons
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  // Helper to launch URLs safely
  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      Fluttertoast.showToast(msg: 'Could not launch URL');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("About Minber TV"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(child: Image.asset('assets/images/minber.jpg', height: 80)),
          const SizedBox(height: 16),
          Text(
            "Faith, culture and history play a significant role in the development of a country. Minber has been able to leave a significant mark in this field over the years, aiming to form a generation that helps the religion and contributes positively to the country.",
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 24),

          _InfoCard(
            icon: Icons.trending_up_rounded,
            title: "Our Journey",
            content:
                "Founded with the vision of being an institution that brings about universal change, Minber Multimedia Production continues to achieve its goals by producing high-quality, artistic media products that have gained a good reputation and high acceptance among the audience.",
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.shield_moon_outlined,
            title: "Our Core Principles",
            contentWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPrincipleItem(
                    context, Icons.history_edu_rounded, "History and Culture"),
                _buildPrincipleItem(
                    context, Icons.groups_rounded, "Community Building"),
                _buildPrincipleItem(
                    context, Icons.diversity_3_rounded, "Solidarity"),
                _buildPrincipleItem(context, Icons.self_improvement_rounded,
                    "Spiritual Prosperity"),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ✅ UI/UX UPDATE: Updated community card with new stats and icon buttons
          _InfoCard(
            icon: Icons.connect_without_contact_rounded,
            title: "Join Our Community",
            contentWidget: Column(
              children: [
                Text(
                  "With over 6,600 videos produced, our YouTube channel alone attracts millions of monthly views, showcasing our massive reach and viewer engagement.",
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                _buildStatCounter(theme, "YouTube Subscribers", "760,000+"),
                const Divider(height: 24),
                Wrap(
                  spacing: 16.0,
                  runSpacing: 12.0,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildSocialIconButton(context,
                        icon: FontAwesomeIcons.globe,
                        label: "Website",
                        onTap: () => _launchURL('https://minbertv.com/')),
                    _buildSocialIconButton(context,
                        icon: FontAwesomeIcons.youtube,
                        label: "YouTube",
                        onTap: () =>
                            _launchURL('https://www.youtube.com/@minbertv1')),
                    _buildSocialIconButton(context,
                        icon: FontAwesomeIcons.telegram,
                        label: "Telegram",
                        onTap: () => _launchURL('https://t.me/minbertv')),
                    _buildSocialIconButton(context,
                        icon: FontAwesomeIcons.tiktok,
                        label: "TikTok",
                        onTap: () =>
                            _launchURL('https://www.tiktok.com/@minber_tv')),
                    _buildSocialIconButton(context,
                        icon: FontAwesomeIcons.xTwitter,
                        label: "X",
                        onTap: () => _launchURL('https://x.com/minbertv')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _InfoCard(
            icon: Icons.satellite_alt_outlined,
            title: "Broadcast Information",
            contentWidget: Column(
              children: [
                Text(
                    "Currently, Minber TV is broadcast worldwide on Ethio-Sat.",
                    style: textTheme.bodyLarge),
                const Divider(height: 24),
                _buildBroadcastDetail(context, "Frequency:", "11545"),
                _buildBroadcastDetail(context, "Symbol Rate:", "30000"),
                _buildBroadcastDetail(context, "Polarization:", "Horizontal"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildPrincipleItem(BuildContext context, IconData icon, String text) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Row(children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyLarge))
        ]));
  }

  Widget _buildBroadcastDetail(
      BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Theme.of(context).hintColor)),
              IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    Fluttertoast.showToast(msg: "$label copied");
                  },
                  tooltip: "Copy"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCounter(ThemeData theme, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12)),
      child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(style: theme.textTheme.titleMedium, children: [
            TextSpan(text: '$label: '),
            TextSpan(
                text: value,
                style: const TextStyle(fontWeight: FontWeight.bold))
          ])),
    );
  }

  // ✅ UI/UX UPDATE: New widget for a beautiful social icon button
  Widget _buildSocialIconButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.surfaceVariant,
            child: FaIcon(icon,
                color: theme.colorScheme.onSurfaceVariant, size: 20),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? content;
  final Widget? contentWidget;

  const _InfoCard(
      {required this.icon,
      required this.title,
      this.content,
      this.contentWidget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(title,
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            if (contentWidget != null) contentWidget!,
            if (content != null)
              Text(content!, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
          ],
        ),
      ),
    );
  }
}
