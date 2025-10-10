// lib/screens/change_password.dart (Fully Updated & Ready to Paste)

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  // --- Methods for real-time validation ---
  bool _has8Chars = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    // Add a listener to the new password controller to update the checklist in real-time
    _newPasswordController.addListener(_updatePasswordRequirements);
  }

  @override
  void dispose() {
    // Clean up the controllers and the listener when the widget is disposed
    _currentPasswordController.dispose();
    _newPasswordController.removeListener(_updatePasswordRequirements);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordRequirements() {
    setState(() {
      final password = _newPasswordController.text;
      _has8Chars = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }

  void _changePassword() {
    // Hide keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    if (_formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg: "Password Changed Successfully 🎉",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
        msg: "Please correct the errors to continue",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using Theme for consistent colors and styles
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        // No colors needed here; it will automatically use the theme's AppBarTheme
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // --- HEADER ---
              Icon(
                Icons.security_update_good_outlined,
                size: 60,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                "Create a New Password",
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Your new password must be different from previous ones.",
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // --- TEXT FORM FIELDS (Updated with modern styling) ---
              _buildPasswordField(
                controller: _currentPasswordController,
                label: "Current Password",
                isObscured: _obscureCurrentPassword,
                toggleVisibility: () {
                  setState(
                      () => _obscureCurrentPassword = !_obscureCurrentPassword);
                },
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter your current password";
                  if (value.length < 6)
                    return "Password must be at least 6 characters";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _newPasswordController,
                label: "New Password",
                isObscured: _obscureNewPassword,
                toggleVisibility: () {
                  setState(() => _obscureNewPassword = !_obscureNewPassword);
                },
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter a new password";
                  if (!_has8Chars || !_hasUppercase || !_hasNumber)
                    return "Password does not meet requirements";
                  if (value == _currentPasswordController.text)
                    return "New password must be different";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: "Confirm New Password",
                isObscured: _obscureConfirmPassword,
                toggleVisibility: () {
                  setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please confirm your new password";
                  if (value != _newPasswordController.text)
                    return "Passwords do not match";
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- ✅ UI/UX UPDATE: Interactive Password Checklist ---
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Password must contain:", style: textTheme.titleSmall),
                    const SizedBox(height: 12),
                    _PasswordRequirementItem(
                        isValid: _has8Chars, text: "At least 8 characters"),
                    const SizedBox(height: 8),
                    _PasswordRequirementItem(
                        isValid: _hasUppercase,
                        text: "At least one uppercase letter (A-Z)"),
                    const SizedBox(height: 8),
                    _PasswordRequirementItem(
                        isValid: _hasNumber, text: "At least one number (0-9)"),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- BUTTONS (Updated to use theme styling) ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _changePassword,
                  // The style is now inherited from the global theme for consistency
                  child: const Text(
                    "Update Password",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for cleaner password fields
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required VoidCallback toggleVisibility,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(isObscured
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined),
          onPressed: toggleVisibility,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2.0),
        ),
      ),
      validator: validator,
    );
  }
}

// Helper widget for the animated password requirement checklist items
class _PasswordRequirementItem extends StatelessWidget {
  const _PasswordRequirementItem({required this.isValid, required this.text});

  final bool isValid;
  final String text;

  @override
  Widget build(BuildContext context) {
    final successColor = Colors.green.shade600;
    final defaultColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            isValid ? Icons.check_circle : Icons.circle_outlined,
            key: ValueKey<bool>(isValid), // Important for AnimatedSwitcher
            color: isValid ? successColor : defaultColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: isValid ? successColor : defaultColor,
            fontWeight: isValid ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
