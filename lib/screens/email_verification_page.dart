import 'dart:async'; // Import for the Timer
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../core/app_colors.dart'; // Assuming AppColors is defined

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
  bool _isVerifying = false; // For the main verify button
  bool _isResending = false; // For the resend button

  // --- STATE FOR RESEND TIMER ---
  Timer? _timer;
  int _start = 60; // Cooldown duration in seconds
  bool _isResendButtonEnabled = true;

  // --- API ENDPOINTS ---
  final String verifyUrl = "http://msa.merkuz.com:3636/users/verify-email";
  final String resendOtpUrl = "http://msa.merkuz.com:3636/users/resend-otp";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel(); // Important to cancel the timer to prevent memory leaks
    super.dispose();
  }

  void _showToast(String message, {Color bgColor = Colors.red}) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: bgColor,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void startTimer() {
    setState(() {
      _isResendButtonEnabled = false;
      _start = 60; // Reset timer to 60 seconds
    });
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            timer.cancel();
            _isResendButtonEnabled = true;
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  // --- NEW: RESEND OTP FUNCTION ---
  Future<void> _resendOtp() async {
    if (mounted) setState(() => _isResending = true);
    _logger.i('--- RESEND OTP PROCESS STARTED ---');

    final requestBody = {"email": widget.email};
    final jsonBody = jsonEncode(requestBody);

    try {
      final response = await http.post(
        Uri.parse(resendOtpUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonBody,
      );

      _logger.i("Resend OTP Status Code: ${response.statusCode}");
      _logger.d("Resend OTP Response: ${response.body}");

      if (response.statusCode == 200) {
        _showToast("✅ A new OTP has been sent to your email.",
            bgColor: Colors.green);
        startTimer(); // Start the cooldown timer on success
      } else {
        final responseData = jsonDecode(response.body);
        String errorMessage = responseData["message"] ??
            "Failed to resend OTP. Please try again.";
        _showToast("❌ $errorMessage");
      }
    } catch (e, st) {
      _logger.f('Fatal Resend OTP Exception:', error: e, stackTrace: st);
      _showToast("⚠️ An unexpected error occurred: $e");
    } finally {
      if (mounted) setState(() => _isResending = false);
      _logger.i('--- RESEND OTP PROCESS ENDED ---');
    }
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) {
      _logger.w("OTP validation failed.");
      return;
    }

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _logger.w("OTP verification attempt while offline.");
      _showToast("❌ You are offline. Please check your internet connection.");
      return;
    }

    if (mounted) setState(() => _isVerifying = true);
    _logger.i('--- EMAIL VERIFICATION PROCESS STARTED ---');

    final requestBody = {
      "email": widget.email,
      "otp": _otpController.text.trim(),
    };
    final jsonBody = jsonEncode(requestBody);

    _logger.i('Request URL: $verifyUrl');
    _logger.d('Request JSON Body: $jsonBody');

    try {
      final response = await http.post(
        Uri.parse(verifyUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonBody,
      );

      _logger.i("Status Code Received: ${response.statusCode}");
      _logger.d("Response Body Received: ${response.body}");
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _logger.i("Email successfully verified.");
        _timer?.cancel(); // Stop the timer if verification is successful
        _showToast("✅ Email verified successfully! Please log in.",
            bgColor: Colors.green);

        // Navigate to login and remove all previous routes from the stack
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
      } else {
        String errorMessage =
            responseData["message"] ?? "Invalid OTP or an error occurred.";
        _logger.e('API Error: ${response.statusCode} - $errorMessage');
        _showToast("❌ $errorMessage");
      }
    } catch (e, st) {
      _logger.f('Fatal Unhandled Exception:', error: e, stackTrace: st);
      _showToast("⚠️ An unexpected error occurred: $e");
    } finally {
      _logger.i('--- EMAIL VERIFICATION PROCESS ENDED ---');
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Email Verification"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.1),
              Icon(Icons.mark_email_read,
                  size: size.width * 0.3, color: AppColors.primary),
              SizedBox(height: size.height * 0.03),
              Text(
                "Check Your Email",
                style: TextStyle(
                  fontSize: size.width * 0.07,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: size.height * 0.02),
              Text(
                "We have sent a verification code (OTP) to your email address:",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: size.width * 0.04),
              ),
              SizedBox(height: size.height * 0.01),
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: size.width * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: size.height * 0.04),
              TextFormField(
                controller: _otpController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6, // Assuming OTP is 6 digits
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter the OTP";
                  }
                  if (value.length < 6) {
                    return "OTP must be 6 digits";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "OTP Code",
                  hintText: "Enter the 6-digit code",
                  counterText: "",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                style: TextStyle(fontSize: size.width * 0.05, letterSpacing: 8),
              ),
              SizedBox(height: size.height * 0.04),
              SizedBox(
                width: double.infinity,
                height: size.height * 0.07,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Verify",
                          style: TextStyle(
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: size.height * 0.03),

              // --- NEW: RESEND OTP BUTTON AND TIMER ---
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
                              ? AppColors.primary
                              : Colors.grey,
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
