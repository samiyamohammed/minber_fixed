import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/app_colors.dart';

class UpgradePlanPage extends StatefulWidget {
  const UpgradePlanPage({super.key});

  @override
  State<UpgradePlanPage> createState() => _UpgradePlanPageState();
}

class _UpgradePlanPageState extends State<UpgradePlanPage> {
  int _selectedIndex = 4; // Sub Apps tab
  String _selectedPlan = 'pro'; // Default selected plan

  final List<Map<String, dynamic>> _planOptions = [
    {
      'id': 'basic',
      'name': 'Basic Plan',
      'price': '\$9.99',
      'period': 'per month',
      'features': [
        'Access to essential features',
        'Limited storage',
        'Standard support',
      ],
      'popular': false,
    },
    {
      'id': 'pro',
      'name': 'Pro Plan',
      'price': '\$19.99',
      'period': 'per month',
      'features': [
        'All Basic features',
        'Enhanced storage',
        'Priority support',
        'Advanced analytics',
      ],
      'popular': true,
    },
    {
      'id': 'premium',
      'name': 'Premium Plan',
      'price': '\$49.99',
      'period': 'per year',
      'features': [
        'All Pro features',
        'Unlimited storage',
        '24/7 Premium support',
        'Custom integrations',
        'Dedicated account manager',
      ],
      'popular': false,
    },
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/watch');
        break;
      case 2:
        Navigator.pushNamed(context, '/prayer');
        break;
      case 3:
        Navigator.pushNamed(context, '/chat');
        break;
      case 4:
        // Already on UpgradePlanPage
        break;
    }
  }

  void _proceedToPayment() {
    final selectedPlan = _planOptions.firstWhere(
      (plan) => plan['id'] == _selectedPlan,
    );
    Fluttertoast.showToast(
      msg: "Proceeding to payment for ${selectedPlan['name']}",
    );
    // Navigate to payment gateway here
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Select Your Plan",
          style: TextStyle(
            fontSize: size.width * 0.05,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: theme.iconTheme.color,
              size: size.width * 0.06,
            ),
            onPressed: () {
              Fluttertoast.showToast(msg: "Plan selection help");
            },
          ),
          Padding(
            padding: EdgeInsets.only(right: size.width * 0.03),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, "/profile");
              },
              borderRadius: BorderRadius.circular(50),
              child: CircleAvatar(
                radius: size.width * 0.05,
                backgroundImage: const AssetImage("assets/images/profile.jpg"),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _planOptions.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: size.height * 0.03),
              itemBuilder: (context, index) {
                final plan = _planOptions[index];
                final isSelected = plan['id'] == _selectedPlan;

                return Container(
                  padding: EdgeInsets.all(size.width * 0.04),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 2)
                        : Border.all(color: theme.dividerColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (plan['popular'] == true)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.03,
                            vertical: size.height * 0.005,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "MOST POPULAR",
                            style: TextStyle(
                              fontSize: size.width * 0.03,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (plan['popular'] == true)
                        SizedBox(height: size.height * 0.01),
                      Text(
                        plan['name'],
                        style: TextStyle(
                          fontSize: size.width * 0.045,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: size.height * 0.005),
                      Text(
                        plan['period'],
                        style: TextStyle(
                          fontSize: size.width * 0.035,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      SizedBox(height: size.height * 0.01),
                      Text(
                        plan['price'],
                        style: TextStyle(
                          fontSize: size.width * 0.06,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      Divider(color: theme.dividerColor),
                      SizedBox(height: size.height * 0.02),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(plan['features'].length, (
                          featureIndex,
                        ) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: size.height * 0.01,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: size.width * 0.04,
                                ),
                                SizedBox(width: size.width * 0.02),
                                Expanded(
                                  child: Text(
                                    plan['features'][featureIndex],
                                    style: TextStyle(
                                      fontSize: size.width * 0.035,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: size.height * 0.02),
                      RadioListTile(
                        value: plan['id'],
                        groupValue: _selectedPlan,
                        onChanged: (value) {
                          setState(() {
                            _selectedPlan = value.toString();
                          });
                        },
                        title: Text(
                          "Select Plan",
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: size.height * 0.04),
            // Secure Payment Section
            Container(
              padding: EdgeInsets.all(size.width * 0.04),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Secure Payment with Chapa",
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Text(
                    "All transactions are securely processed through the Chapa payment gateway.",
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  Container(
                    height: size.height * 0.06,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Center(
                      child: Text(
                        "CHAPA",
                        style: TextStyle(
                          fontSize: size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _proceedToPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: theme.textTheme.labelLarge?.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: size.height * 0.02,
                        ),
                      ),
                      child: Text(
                        "Proceed to Chapa",
                        style: TextStyle(
                          fontSize: size.width * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.03),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: theme.iconTheme.color?.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: size.width * 0.03,
        unselectedFontSize: size.width * 0.03,
        iconSize: size.width * 0.06,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: size.width * 0.06),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tv, size: size.width * 0.06),
            label: "Watch",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mosque, size: size.width * 0.06),
            label: "Prayer",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline, size: size.width * 0.06),
            activeIcon: Icon(Icons.chat_bubble, size: size.width * 0.06),
            label: "Chat Box",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore, size: size.width * 0.06),
            label: "Sub Apps",
          ),
        ],
      ),
    );
  }
}
