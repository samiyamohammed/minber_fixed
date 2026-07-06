// lib/screens/reset_password_screen.dart (Fully Corrected & Ready to Paste)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _logger = Logger();

  bool _isLoading = false;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  bool _has8Chars = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordRequirements);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.removeListener(_updatePasswordRequirements);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordRequirements() {
    setState(() {
      final password = _passwordController.text;
      _has8Chars = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (!_has8Chars ||
        !_hasUppercase ||
        !_hasLowercase ||
        !_hasNumber ||
        !_hasSpecialChar) {
      return 'Password does not meet all requirements';
    }
    return null;
  }

  Future<void> _resetPassword() async {
    // ✅ 1. REMOVED the email parameter
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Prepare the request body without the email
    final requestBody = {
      "token": _tokenController.text.trim(),
      "newPassword": _passwordController.text.trim()
    };

    _logger.i(
        "Attempting to reset password with body: ${jsonEncode(requestBody)}");

    try {
      final response = await http.post(
        Uri.parse("https://msa.merkuz.com/users/reset-password"),
        headers: {"Content-Type": "application/json"},
        // ✅ 2. SEND THE CORRECT BODY (without email)
        body: jsonEncode(requestBody),
      );

      _logger.d(
          "Reset Password Response - Status: ${response.statusCode}, Body: ${response.body}");

      if (mounted) {
        if (response.statusCode == 200 || response.statusCode == 201) {
          Fluttertoast.showToast(
              msg: "Password reset successfully! Please log in.",
              backgroundColor: Colors.green,
              toastLength: Toast.LENGTH_LONG);
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        } else {
          // Provide a more detailed error message
          final responseData = jsonDecode(response.body);
          final message = responseData['message']?.toString() ??
              "An unknown error occurred.";
          _logger.e("Password reset failed: $message");
          Fluttertoast.showToast(
              msg: "Error: $message", toastLength: Toast.LENGTH_LONG);
        }
      }
    } catch (e) {
      _logger.e("An exception occurred during password reset", error: e);
      Fluttertoast.showToast(
          msg: "An error occurred. Please check your connection.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    // ✅ 3. REMOVED the logic to get email from arguments

    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_reset_rounded,
                    size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text("Create New Password",
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                    "Enter the code from your email and create a new, strong password.",
                    textAlign: TextAlign.center,
                    style:
                        textTheme.bodyLarge?.copyWith(color: theme.hintColor)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                      labelText: "Reset Code",
                      prefixIcon: Icon(Icons.confirmation_number_outlined)),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? "Please enter the code"
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isNewPasswordObscured,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isNewPasswordObscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() =>
                          _isNewPasswordObscured = !_isNewPasswordObscured),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),
                _buildPasswordChecklist(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _isConfirmPasswordObscured,
                  decoration: InputDecoration(
                    labelText: "Confirm New Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPasswordObscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() =>
                          _isConfirmPasswordObscured =
                              !_isConfirmPasswordObscured),
                    ),
                  ),
                  validator: (value) => (value != _passwordController.text)
                      ? "Passwords do not match"
                      : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _resetPassword, // ✅ 4. CALL THE FUNCTION WITHOUT ARGUMENTS
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 3))
                        : const Text("Reset Password",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordChecklist() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PasswordRequirementItem(
              isValid: _has8Chars, text: "At least 8 characters"),
          const SizedBox(height: 8),
          _PasswordRequirementItem(
              isValid: _hasUppercase, text: "An uppercase letter (A-Z)"),
          const SizedBox(height: 8),
          _PasswordRequirementItem(
              isValid: _hasLowercase, text: "A lowercase letter (a-z)"),
          const SizedBox(height: 8),
          _PasswordRequirementItem(isValid: _hasNumber, text: "A number (0-9)"),
          const SizedBox(height: 8),
          _PasswordRequirementItem(
              isValid: _hasSpecialChar, text: "A special character (!@#\$%)"),
        ],
      ),
    );
  }
}

class _PasswordRequirementItem extends StatelessWidget {
  final bool isValid;
  final String text;
  const _PasswordRequirementItem({required this.isValid, required this.text});

  @override
  Widget build(BuildContext context) {
    final successColor = Colors.green.shade600;
    final defaultColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
              isValid ? Icons.check_circle_rounded : Icons.circle_outlined,
              key: ValueKey<bool>(isValid),
              color: isValid ? successColor : defaultColor,
              size: 20),
        ),
        const SizedBox(width: 12),
        Text(text,
            style: TextStyle(
                color: isValid ? successColor : defaultColor,
                fontWeight: isValid ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}
