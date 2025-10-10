// lib/screens/email_verification_page.dart (Fully Updated & Ready to Paste)

import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:pinput/pinput.dart'; // ✅ UI/UX UPDATE: Import for the modern OTP field

class EmailVerificationPage extends StatefulWidget {
  final String email;

  const EmailVerificationPage({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final Logger _logger = Logger();

  // --- STATE FOR API CALLS ---
  bool _isVerifying = false;
  bool _isResending = false;

  // --- STATE FOR RESEND TIMER ---
  Timer? _timer;
  int _start = 60;
  bool _isResendButtonEnabled = true;

  // --- API ENDPOINTS (Unchanged) ---
  final String verifyUrl = "http://msa.merkuz.com:3636/users/verify-email";
  final String resendOtpUrl = "http://msa.merkuz.com:3636/users/resend-otp";

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // --- CORE LOGIC (Unchanged) ---
  void _showToast(String message, {Color bgColor = Colors.red}) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: bgColor,
        textColor: Colors.white);
  }

  void startTimer() {
    setState(() {
      _isResendButtonEnabled = false;
      _start = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          _isResendButtonEnabled = true;
        });
      } else {
        setState(() => _start--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (mounted) setState(() => _isResending = true);
    try {
      final response = await http.post(Uri.parse(resendOtpUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"email": widget.email}));
      if (response.statusCode == 200) {
        _showToast("✅ A new OTP has been sent.", bgColor: Colors.green);
        startTimer();
      } else {
        final error =
            jsonDecode(response.body)["message"] ?? "Failed to resend OTP.";
        _showToast("❌ $error");
      }
    } catch (e) {
      _showToast("⚠️ An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      _showToast("❌ You are offline. Please check your connection.");
      return;
    }

    if (mounted) setState(() => _isVerifying = true);
    try {
      final response = await http.post(Uri.parse(verifyUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(
              {"email": widget.email, "otp": _otpController.text.trim()}));
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _timer?.cancel();
        _showToast("✅ Email verified! Please log in.", bgColor: Colors.green);
        if (mounted)
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
      } else {
        _showToast("❌ ${responseData["message"] ?? "Invalid OTP."}");
      }
    } catch (e) {
      _showToast("⚠️ An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ UI/UX UPDATE: Using theme for all colors and styles
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // ✅ UI/UX UPDATE: Pinput themes for modern OTP field
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: textTheme.headlineSmall,
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
    );
    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
    );
    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: colorScheme.primary.withOpacity(0.1),
        border: Border.all(color: colorScheme.primary),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Email Verification"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.mark_email_read_outlined,
                    size: 80, color: colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  "Check Your Email",
                  style: textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  "We've sent a 6-digit code to:",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // ✅ UI/UX UPDATE: Modern Pinput OTP Field
                Pinput(
                  controller: _otpController,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Please enter the code";
                    if (value.length < 6) return "Code must be 6 digits";
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyEmail,
                    child: _isVerifying
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 3))
                        : const Text("Verify & Continue",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),

                // Resend OTP Button
                _isResending
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator())
                    : TextButton(
                        onPressed: _isResendButtonEnabled ? _resendOtp : null,
                        child: Text(
                          _isResendButtonEnabled
                              ? "Didn't receive code? Resend"
                              : "Resend in $_start s",
                          style: TextStyle(
                            color: _isResendButtonEnabled
                                ? colorScheme.primary
                                : theme.disabledColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
