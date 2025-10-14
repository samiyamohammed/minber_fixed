// lib/screens/forgot_password_screen.dart (Fully Corrected & Ready to Paste)

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

  Future<void> _requestReset() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://msa.merkuz.com:3636/users/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _emailController.text.trim()}),
      );

      _logger.d(
          "Forgot Password Response - Status: ${response.statusCode}, Body: ${response.body}");

      if (mounted) {
        Fluttertoast.showToast(
          msg:
              "If an account with that email exists, a reset code has been sent.",
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_LONG,
        );

        // ✅ CORRECTION: Removed the 'arguments' property as it's not needed.
        Navigator.pushReplacementNamed(context, '/reset-password');
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_reset_outlined,
                    size: 80, color: colorScheme.primary),
                const SizedBox(height: 24),
                Text("Forgot Your Password?",
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                    "Enter the email associated with your account and we'll send a code to reset your password.",
                    textAlign: TextAlign.center,
                    style:
                        textTheme.bodyLarge?.copyWith(color: theme.hintColor)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12))),
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
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestReset,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 3))
                        : const Text("Send Code",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Back to Login"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
