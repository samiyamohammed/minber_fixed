// lib/screens/upgrade_plan_page.dart (Fully Updated & Ready to Paste)

import 'package:flutter/material.dart';

// ✅ UI/UX UPDATE: A structured data model for plans
class Plan {
  final String id;
  final String name;
  final String monthlyPrice;
  final String yearlyPrice;
  final List<String> features;
  final bool isPopular;

  Plan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.features,
    this.isPopular = false,
  });
}

class UpgradePlanPage extends StatefulWidget {
  const UpgradePlanPage({super.key});

  @override
  State<UpgradePlanPage> createState() => _UpgradePlanPageState();
}

class _UpgradePlanPageState extends State<UpgradePlanPage> {
  int _selectedIndex = 4; // Sub Apps tab
  String _selectedPlanId = 'pro'; // Default selected plan
  bool _isYearlyBilling = false; // To control the billing cycle toggle

  // ✅ CORRECTION: Updated prices to ETB
  final List<Plan> _planOptions = [
    Plan(
        id: 'basic',
        name: 'Basic Plan',
        monthlyPrice: '250 ETB',
        yearlyPrice: '2500 ETB',
        features: [
          'Access to essential features',
          'Limited storage',
          'Standard support'
        ]),
    Plan(
        id: 'pro',
        name: 'Pro Plan',
        monthlyPrice: '500 ETB',
        yearlyPrice: '5000 ETB',
        features: [
          'All Basic features',
          'Enhanced storage',
          'Priority support',
          'Advanced analytics'
        ],
        isPopular: true),
    Plan(
        id: 'premium',
        name: 'Premium Plan',
        monthlyPrice: '1000 ETB',
        yearlyPrice: '10000 ETB',
        features: [
          'All Pro features',
          'Unlimited storage',
          '24/7 Premium support',
          'Custom integrations'
        ]),
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
        break;
    }
    if (routeName.isNotEmpty)
      Navigator.pushReplacementNamed(context, routeName);
  }

  // ✅ CORRECTION: This function now navigates to the coming soon page
  void _proceedToPayment() {
    Navigator.pushNamed(
      context,
      '/coming-soon',
      arguments: 'Payment Gateway',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Select Your Plan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildBillingToggle(theme),
            const SizedBox(height: 24),
            ..._planOptions.map((plan) => _buildPlanCard(theme, plan)).toList(),
            const SizedBox(height: 24),
            _buildPaymentCard(theme),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  // --- WIDGET BUILDER METHODS (Unchanged) ---

  Widget _buildBillingToggle(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleOption(theme, "Monthly", !_isYearlyBilling),
            _buildToggleOption(theme, "Yearly", _isYearlyBilling),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(ThemeData theme, String title, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _isYearlyBilling = (title == "Yearly")),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            if (title == "Yearly") ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6)),
                child: Text("SAVE 15%",
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold)),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(ThemeData theme, Plan plan) {
    final isSelected = plan.id == _selectedPlanId;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlanId = plan.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color:
                  isSelected ? theme.colorScheme.primary : theme.dividerColor,
              width: isSelected ? 2.0 : 1.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      blurRadius: 10)
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(plan.name,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (plan.isPopular)
                  Chip(
                      label: const Text("Most Popular"),
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    _isYearlyBilling ? plan.yearlyPrice : plan.monthlyPrice,
                    key: ValueKey<bool>(_isYearlyBilling),
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                  child: Text(_isYearlyBilling ? "/ year" : "/ month",
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.hintColor)),
                ),
              ],
            ),
            const Divider(height: 32),
            ...plan.features
                .map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 20, color: Colors.green.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(feature,
                                style: theme.textTheme.bodyMedium)),
                      ]),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Secure Payment",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
                "All transactions are encrypted and processed securely via Chapa.",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 16),
            Image.asset('assets/images/chapa_logo.png', height: 40),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _proceedToPayment,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text("Proceed to Payment",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
