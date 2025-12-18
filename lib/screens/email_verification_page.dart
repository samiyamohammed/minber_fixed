// lib/screens/email_verification_page.dart (Final Simplified Version)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';

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

  bool _isVerifying = false;
  bool _isResending = false;

  // Timer State
  Timer? _timer;
  int _start = 60;
  bool _isResendButtonEnabled =
      false; // Disabled initially as OTP is sent on signup

  // Backend Endpoints
  final String verifyUrl = "http://msa.merkuz.com:3636/users/verify-email";
  final String resendOtpUrl = "http://msa.merkuz.com:3636/users/resend-otp";

  @override
  void initState() {
    super.initState();
    startTimer(); // Start countdown immediately upon entering screen
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

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
      if (!mounted) return;
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
      final response = await http.post(
        Uri.parse(resendOtpUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email}),
      );

      // Relaxed check: Accept 200 OK or 201 Created
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showToast("✅ OTP resent successfully.", bgColor: Colors.green);
        startTimer();
      } else {
        // Safe decoding in case body is empty or not JSON
        String errorMsg = "Failed to resend OTP.";
        try {
          final body = jsonDecode(response.body);
          if (body["message"] != null) errorMsg = body["message"];
        } catch (_) {}

        _showToast("❌ $errorMsg");
      }
    } catch (e) {
      _showToast("⚠️ Network error. Please try again.");
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyEmail() async {
    // Basic validation only
    if (_otpController.text.length < 6) {
      _showToast("⚠️ Please enter the full 6-digit code.");
      return;
    }

    if (mounted) setState(() => _isVerifying = true);

    try {
      final response = await http.post(
        Uri.parse(verifyUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"email": widget.email, "otp": _otpController.text.trim()}),
      );

      // Relaxed check: Accept 200 OK or 201 Created
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _timer?.cancel();
        _showToast("✅ Email verified! Please log in.", bgColor: Colors.green);

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
      } else {
        String errorMsg = "Invalid OTP.";
        try {
          final body = jsonDecode(response.body);
          if (body["message"] != null) errorMsg = body["message"];
        } catch (_) {}

        _showToast("❌ $errorMsg");
      }
    } catch (e) {
      _showToast("⚠️ Network error. Please try again.");
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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

    return Scaffold(
      appBar: AppBar(title: const Text("Email Verification")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              Text("We've sent a 6-digit code to:", style: textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style:
                    textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Pinput(
                controller: _otpController,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: colorScheme.primary, width: 2),
                  ),
                ),
                // Auto-submit when filled is often better UX
                onCompleted: (pin) => _verifyEmail(),
              ),
              const SizedBox(height: 32),
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
              _isResending
                  ? const SizedBox(
                      height: 24, width: 24, child: CircularProgressIndicator())
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
    );
  }
}
