// lib/screens/forgot_password_screen.dart (Fully Updated & Ready to Paste)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  final _logger = Logger();

  // --- CORE LOGIC (Unchanged) ---
  Future<void> _requestReset() async {
    // Hide keyboard on submission
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _logger.i("Requesting password reset for: ${_emailController.text.trim()}");

    try {
      final response = await http.post(
        Uri.parse("http://msa.merkuz.com:3636/users/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _emailController.text.trim()}),
      );

      _logger.d(
          "Forgot Password Response - Status: ${response.statusCode}, Body: ${response.body}");

      if (mounted) {
        if (response.statusCode == 201) {
          Fluttertoast.showToast(
            msg:
                "If an account with that email exists, a reset code has been sent.",
            backgroundColor: Colors.green,
            toastLength: Toast.LENGTH_LONG,
          );
          // Navigate to the next screen where the user will enter the token.
          // IMPORTANT: Make sure you pass the email to the reset password screen.
          Navigator.pushReplacementNamed(
            context,
            '/reset-password',
            arguments: _emailController.text.trim(), // Pass email as argument
          );
        } else {
          // It's better practice to show the same success message even on failure
          // to prevent users from checking which emails are registered.
          Fluttertoast.showToast(
            msg:
                "If an account with that email exists, a reset code has been sent.",
            backgroundColor: Colors.green,
            toastLength: Toast.LENGTH_LONG,
          );
          Navigator.pushReplacementNamed(
            context,
            '/reset-password',
            arguments: _emailController.text.trim(),
          );
        }
      }
    } catch (e) {
      _logger.e("Error requesting password reset", error: e);
      Fluttertoast.showToast(
          msg: "An error occurred. Please check your connection.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ UI/UX UPDATE: Using theme for all colors and styles
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ UI/UX UPDATE: Added a prominent visual icon
                Icon(
                  Icons.lock_reset_outlined,
                  size: 80,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),

                // ✅ UI/UX UPDATE: Using theme text styles for consistency
                Text(
                  "Forgot Your Password?",
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "Enter the email associated with your account and we'll send a code to reset your password.",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 32),

                // ✅ UI/UX UPDATE: Modernized TextFormField
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty ||
                        !value.contains('@')) {
                      return "Please enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ✅ UI/UX UPDATE: Button inherits style from the global theme
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestReset,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          )
                        : const Text("Send Code",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Back to Login"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
