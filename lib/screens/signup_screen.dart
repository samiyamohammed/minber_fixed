// lib/screens/signup_page.dart (Fully Updated & Ready to Paste)

import 'dart:convert';
import 'package:minber_super_app_new_fixed/screens/email_verification_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class SignUpPage extends StatefulWidget { 
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  final Logger _logger = Logger();

  final String registerUrl = "http://msa.merkuz.com:3636/users/register";

  // ✅ UI/UX UPDATE: State for real-time password validation
  bool _has8Chars = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordRequirements);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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
      _hasNumber = password.contains(RegExp(r'[0-9]'));
    });
  }

  void _showToast(String message, {Color bgColor = Colors.red}) {
    Fluttertoast.showToast(
        msg: message, backgroundColor: bgColor, toastLength: Toast.LENGTH_LONG);
  }

  Future<void> _signUp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _showToast("❌ No internet connection.");
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim()
        }),
      );
      final responseData = jsonDecode(response.body);

      if (mounted) {
        if (response.statusCode == 201) {
          final apiMessage = responseData["message"] ??
              "Registration successful! Please verify your email.";
          _showToast(apiMessage, bgColor: Colors.green);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EmailVerificationPage(
                      email: _emailController.text.trim())));
        } else {
          String errorMessage =
              responseData["message"] ?? "An unexpected error occurred.";
          _showToast("❌ Error: $errorMessage");
        }
      }
    } catch (e) {
      _showToast("⚠️ An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/minber.jpg', height: 80),
                  const SizedBox(height: 24),
                  Text("Create Your Account",
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Join us to unlock a world of features.",
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: theme.hintColor)),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: "Username",
                        prefixIcon: Icon(Icons.person_outline_rounded)),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Username is required"
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: "Email Address",
                        prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty || !v.contains('@'))
                            ? "Please enter a valid email"
                            : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isPasswordObscured,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordObscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(
                            () => _isPasswordObscured = !_isPasswordObscured),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? "Password is required"
                        : ((!_has8Chars || !_hasUppercase || !_hasNumber)
                            ? "Password does not meet requirements"
                            : null),
                  ),
                  const SizedBox(height: 16),

                  // ✅ UI/UX UPDATE: Interactive password strength checklist
                  _buildPasswordChecklist(),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _isConfirmPasswordObscured,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_isConfirmPasswordObscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() =>
                            _isConfirmPasswordObscured =
                                !_isConfirmPasswordObscured),
                      ),
                    ),
                    validator: (v) => (v != _passwordController.text)
                        ? "Passwords do not match"
                        : null,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 3))
                            : const Text("Create Account",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?",
                          style: textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("Sign In",
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordChecklist() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _PasswordRequirementItem(
              isValid: _has8Chars, text: "At least 8 characters"),
          const SizedBox(height: 8),
          _PasswordRequirementItem(
              isValid: _hasUppercase,
              text: "Contains an uppercase letter (A-Z)"),
          const SizedBox(height: 8),
          _PasswordRequirementItem(
              isValid: _hasNumber, text: "Contains a number (0-9)"),
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
