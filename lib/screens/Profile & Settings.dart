import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/app_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _darkMode = true;
  bool _twoFactorEnabled = false;

  // -1 means none of the bottom bar items is selected (since Profile is not part of it)
  int _selectedIndex = -1;

  void _onItemTapped(int index) {
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
        Navigator.pushReplacementNamed(context, '/chatBot'); // fixed route name
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/subapps');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile & Settings"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
          child: ListView(
            children: [
              SizedBox(height: size.height * 0.03),

              // User Profile Section
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/editProfile');
                },
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(size.width * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Profile",
                          style: TextStyle(
                            fontSize: size.width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        ListTile(
                          leading: CircleAvatar(
                            radius: size.width * 0.06,
                            backgroundColor: Colors.transparent,
                            backgroundImage: const AssetImage(
                              'assets/images/profile.jpg',
                            ),
                          ),
                          title: Text(
                            "Aisha Rahman",
                            style: TextStyle(
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "aisha.i@example.com",
                            style: TextStyle(fontSize: size.width * 0.035),
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.03,
                              vertical: size.height * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Premium",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: size.width * 0.03,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.02),

              // Preferences Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(size.width * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Preferences",
                        style: TextStyle(
                          fontSize: size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),

                      // Language
                      ListTile(
                        title: Text(
                          "Language",
                          style: TextStyle(fontSize: size.width * 0.04),
                        ),
                        trailing: Text(
                          "English",
                          style: TextStyle(
                            fontSize: size.width * 0.035,
                            color: Colors.grey,
                          ),
                        ),
                        onTap: () {
                          Fluttertoast.showToast(
                            msg: "Language settings clicked",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                        },
                      ),
                      const Divider(height: 1),

                      // Dark Mode
                      // ListTile(
                      //   title: Text(
                      //     "Dark Mode",
                      //     style: TextStyle(fontSize: size.width * 0.04),
                      //   ),
                      //   trailing: Switch(
                      //     value: _darkMode,
                      //     onChanged: (value) {
                      //       setState(() {
                      //         _darkMode = value;
                      //       });
                      //     },
                      //     activeColor: AppColors.primary,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.02),

              // Security Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(size.width * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Security",
                        style: TextStyle(
                          fontSize: size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),

                      // Change Password
                      ListTile(
                        title: Text(
                          "Change Password",
                          style: TextStyle(fontSize: size.width * 0.04),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          size: size.width * 0.06,
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/changePassword');
                        },
                      ),
                      const Divider(height: 1),

                      // Two-Factor Authentication
                      ListTile(
                        title: Text(
                          "Two-Factor Authentication",
                          style: TextStyle(fontSize: size.width * 0.04),
                        ),
                        trailing: Switch(
                          value: _twoFactorEnabled,
                          onChanged: (value) {
                            setState(() {
                              _twoFactorEnabled = value;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.02),

              // Support & Resources Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(size.width * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Support & Resources",
                        style: TextStyle(
                          fontSize: size.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),

                      // Help & FAQ
                      ListTile(
                        title: Text(
                          "Help & FAQ",
                          style: TextStyle(fontSize: size.width * 0.04),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          size: size.width * 0.06,
                        ),
                        onTap: () {
                          Fluttertoast.showToast(
                            msg: "Help & FAQ clicked",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                        },
                      ),
                      const Divider(height: 1),

                      // Contact Support
                      ListTile(
                        title: Text(
                          "Contact Support",
                          style: TextStyle(fontSize: size.width * 0.04),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          size: size.width * 0.06,
                        ),
                        onTap: () {
                          Fluttertoast.showToast(
                            msg: "Contact Support clicked",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.03),

              // Log Out Button
              SizedBox(
                width: double.infinity,
                height: size.height * 0.07,
                child: ElevatedButton(
                  onPressed: () {
                    Fluttertoast.showToast(
                      msg: "Logged out successfully",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      backgroundColor: Colors.green,
                      textColor: Colors.white,
                    );
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(
                    "Log Out",
                    style: TextStyle(
                      fontSize: size.width * 0.045,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.03),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex < 0
            ? 0
            : _selectedIndex, // no highlight when -1
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
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
