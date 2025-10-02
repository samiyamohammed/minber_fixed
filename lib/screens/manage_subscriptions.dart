import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/app_colors.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int _selectedIndex = 0;

  final List<Map<String, String>> _planOptions = [
    {
      'name': 'Basic Plan',
      'price': '\$4.99/month',
      'features': 'Basic features, limited content',
    },
    {
      'name': 'Premium Plan',
      'price': '\$9.99/month',
      'features': 'All features, unlimited access',
    },
    {
      'name': 'Family Plan',
      'price': '\$14.99/month',
      'features': 'For up to 5 family members',
    },
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/media');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/prayer');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/chat');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/subapps');
        break;
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text("Cancel Subscription"),
          content: Text(
            "Are you sure you want to cancel your Premium Plan subscription?",
            style: TextStyle(color: theme.textTheme.bodyLarge!.color),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Keep Subscription",
                style: TextStyle(color: theme.primaryColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Fluttertoast.showToast(
                  msg: "Subscription cancellation requested",
                );
              },
              child: Text(
                "Cancel Subscription",
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Manage Subscription",
          style: TextStyle(
            fontSize: size.width * 0.05,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge!.color,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, size: size.width * 0.06),
            onPressed: () => Fluttertoast.showToast(msg: "Subscription help"),
          ),
          Padding(
            padding: EdgeInsets.only(right: size.width * 0.03),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, "/profile"),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Plan Section
            Text(
              "Current Plan",
              style: TextStyle(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge!.color,
              ),
            ),
            SizedBox(height: size.height * 0.02),
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
                    "Premium Plan - Renews on Mar 7, 2025",
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  _buildDetailRow("Period", "Yearly", theme, size),
                  _buildDetailRow("Type", "Apple", theme, size),
                  _buildDetailRow("Renewal Date", "Mar 7, 2025", theme, size),
                  _buildDetailRow(
                    "Subscription Starts",
                    "Mar 7, 2024",
                    theme,
                    size,
                  ),
                  SizedBox(height: size.height * 0.02),
                  Divider(color: theme.dividerColor),
                  SizedBox(height: size.height * 0.02),
                  Text(
                    "You will be charged for a subscription unless you cancel the trial at least 24 hours before the end date.",
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      color: theme.textTheme.bodyMedium!.color,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: size.height * 0.04),
            Divider(color: theme.dividerColor),
            SizedBox(height: size.height * 0.04),

            // Upgrade Plan Section
            Text(
              "Upgrade Plan",
              style: TextStyle(
                fontSize: size.width * 0.045,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge!.color,
              ),
            ),
            SizedBox(height: size.height * 0.02),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _planOptions.length,
              separatorBuilder: (_, __) => SizedBox(height: size.height * 0.02),
              itemBuilder: (context, index) {
                final plan = _planOptions[index];
                final isCurrentPlan = plan['name'] == 'Premium Plan';

                return Container(
                  padding: EdgeInsets.all(size.width * 0.04),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrentPlan
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            plan['name']!,
                            style: TextStyle(
                              fontSize: size.width * 0.04,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge!.color,
                            ),
                          ),
                          if (isCurrentPlan)
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
                                "Current",
                                style: TextStyle(
                                  fontSize: size.width * 0.03,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.01),
                      Text(
                        plan['price']!,
                        style: TextStyle(
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge!.color,
                        ),
                      ),
                      SizedBox(height: size.height * 0.005),
                      Text(
                        plan['features']!,
                        style: TextStyle(
                          fontSize: size.width * 0.035,
                          color: theme.textTheme.bodyMedium!.color,
                        ),
                      ),
                      SizedBox(height: size.height * 0.01),
                      if (!isCurrentPlan)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Fluttertoast.showToast(
                                msg: "Upgrading to ${plan['name']}",
                              );
                              Navigator.pushNamed(context, "/upgradeplan");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text("Select Plan"),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: size.height * 0.04),

            // Cancel Subscription Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showCancelConfirmation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                ),
                child: Text(
                  "Cancel Subscription",
                  style: TextStyle(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        unselectedItemColor: theme.iconTheme.color,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: size.width * 0.03,
        unselectedFontSize: size.width * 0.03,
        iconSize: size.width * 0.06,
        // backgroundColor: theme.bottomAppBarColor,
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

  Widget _buildDetailRow(
    String label,
    String value,
    ThemeData theme,
    Size size,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: size.height * 0.005),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: size.width * 0.035,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge!.color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: size.width * 0.035,
              color: theme.textTheme.bodyMedium!.color,
            ),
          ),
        ],
      ),
    );
  }
}
