import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/app_colors.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      // ✅ If validation passes
      Fluttertoast.showToast(
        msg: "Password Changed Successfully 🎉",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Navigate back
      Navigator.pop(context);
    } else {
      // ❌ If validation fails
      Fluttertoast.showToast(
        msg: "Please fix the errors above",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                SizedBox(height: size.height * 0.03),

                // Security Icon
                Center(
                  child: Icon(
                    Icons.lock_outline,
                    size: size.width * 0.15,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: size.height * 0.02),

                Center(
                  child: Text(
                    "Update your password",
                    style: TextStyle(
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.01),

                Center(
                  child: Text(
                    "Ensure your account is using a strong, unique password",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.04),

                // Current Password Field
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: "Current Password",
                    prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                      vertical: size.height * 0.02,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your current password";
                    } else if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.02),

                // New Password Field
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    prefixIcon:
                        Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                      vertical: size.height * 0.02,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a new password";
                    } else if (value.length < 8) {
                      return "Password must be at least 8 characters";
                    } else if (value == _currentPasswordController.text) {
                      return "New password must be different from current password";
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.02),

                // Confirm New Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Confirm New Password",
                    prefixIcon:
                        Icon(Icons.lock_outline, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.04,
                      vertical: size.height * 0.02,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm your new password";
                    } else if (value != _newPasswordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.03),

                // Password Requirements
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: EdgeInsets.all(size.width * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Password must include:",
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: size.height * 0.01),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: _newPasswordController.text.length >= 8
                                  ? Colors.green
                                  : Colors.grey,
                              size: size.width * 0.04,
                            ),
                            SizedBox(width: size.width * 0.02),
                            Text(
                              "At least 8 characters",
                              style: TextStyle(
                                fontSize: size.width * 0.035,
                                color: _newPasswordController.text.length >= 8
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.005),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: _newPasswordController.text
                                      .contains(RegExp(r'[A-Z]'))
                                  ? Colors.green
                                  : Colors.grey,
                              size: size.width * 0.04,
                            ),
                            SizedBox(width: size.width * 0.02),
                            Text(
                              "One uppercase letter",
                              style: TextStyle(
                                fontSize: size.width * 0.035,
                                color: _newPasswordController.text
                                        .contains(RegExp(r'[A-Z]'))
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.005),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: _newPasswordController.text
                                      .contains(RegExp(r'[0-9]'))
                                  ? Colors.green
                                  : Colors.grey,
                              size: size.width * 0.04,
                            ),
                            SizedBox(width: size.width * 0.02),
                            Text(
                              "One number",
                              style: TextStyle(
                                fontSize: size.width * 0.035,
                                color: _newPasswordController.text
                                        .contains(RegExp(r'[0-9]'))
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.03),

                // Change Password Button
                SizedBox(
                  width: double.infinity,
                  height: size.height * 0.07,
                  child: ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: Text(
                      "Change Password",
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.02),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: size.height * 0.07,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: size.width * 0.045,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
