// lib/screens/subscription_page.dart (Fully Updated & Ready to Paste)

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// A simple data model for better code structure
class SubscriptionPlan {
  final String name;
  final String price;
  final List<String> features;
  final bool isRecommended;

  SubscriptionPlan({
    required this.name,
    required this.price,
    required this.features,
    this.isRecommended = false,
  });
}

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int _selectedIndex = 0; // For BottomNavBar
  String _selectedPlan = 'Premium Plan'; // To track the chosen plan

  // ✅ UI/UX UPDATE: Using a structured list of plan objects
  final List<SubscriptionPlan> _planOptions = [
    SubscriptionPlan(
      name: 'Basic Plan',
      price: '4.99 ETB / month',
      features: [
        'Ad-supported streaming',
        'Limited content library',
        'Standard definition'
      ],
    ),
    SubscriptionPlan(
      name: 'Premium Plan',
      price: '9.99 ETB / month',
      features: [
        'Ad-free streaming',
        'Full content library',
        'HD & 4K streaming',
        'Offline downloads'
      ],
      isRecommended: true,
    ),
    SubscriptionPlan(
      name: 'Family Plan',
      price: '14.99 ETB / month',
      features: [
        'All Premium features',
        'Up to 5 profiles',
        'Simultaneous streaming'
      ],
    ),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    String routeName = '';
    switch (index) {
      case 0:
        routeName = '/home';
        break;
      case 1:
        routeName = '/media';
        break;
      case 2:
        routeName = '/prayer';
        break;
      case 3:
        routeName = '/chatbot';
        break;
      case 4:
        routeName = '/subapps';
        break;
    }
    if (routeName.isNotEmpty)
      Navigator.pushReplacementNamed(context, routeName);
  }

  void _showCancelConfirmation() {
    // ✅ UI/UX UPDATE: Modern, theme-aware dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Cancel Subscription"),
          content:
              const Text("Are you sure you want to cancel your current plan?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Keep Plan"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
                Fluttertoast.showToast(
                  msg: "Subscription canceled",
                );
              },
              child: Text("Yes, Cancel",
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Subscriptions"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ UI/UX UPDATE: Redesigned "Current Plan" card
            Text("Your Plan",
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildCurrentPlanCard(theme),
            const SizedBox(height: 32),

            // ✅ UI/UX UPDATE: Redesigned "Upgrade Plan" section
            Text("Choose Your Plan",
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _planOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final plan = _planOptions[index];
                return _buildPlanOptionCard(theme, plan);
              },
            ),
            const SizedBox(height: 24),

            // ✅ UI/UX UPDATE: Primary action button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Fluttertoast.showToast(msg: "Proceeding with $_selectedPlan");
                  Navigator.pushNamed(context, "/upgradeplan");
                },
                child: Text("Continue with $_selectedPlan",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),

            // ✅ UI/UX UPDATE: Secondary action button for cancellation
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: _showCancelConfirmation,
                style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error),
                child: const Text("Cancel Subscription"),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildCurrentPlanCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded,
                  color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                "Premium Plan",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Your subscription is active and renews on Mar 7, 2025.",
            style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOptionCard(ThemeData theme, SubscriptionPlan plan) {
    // ✅ UI/UX UPDATE: Interactive, animated plan selection card
    final bool isSelected = plan.name == _selectedPlan;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color:
                      isSelected ? theme.colorScheme.primary : theme.hintColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    plan.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (plan.isRecommended)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text("Recommended",
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondary,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.price, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  ...plan.features
                      .map((feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline_rounded,
                                    size: 18, color: theme.hintColor),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(feature,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                color: theme.hintColor))),
                              ],
                            ),
                          ))
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar(ThemeData theme) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.unselectedWidgetColor,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.tv_outlined),
            activeIcon: Icon(Icons.tv),
            label: "Watch"),
        BottomNavigationBarItem(
            icon: Icon(Icons.mosque_outlined),
            activeIcon: Icon(Icons.mosque),
            label: "Prayer"),
        BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: "Chat Box"),
        BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.apps),
            label: "Sub Apps"),
      ],
    );
  }
}
