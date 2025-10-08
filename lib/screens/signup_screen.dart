import 'dart:convert';
import 'package:minber_super_app_new_fixed/screens/email_verification_page.dart'; // Import the new page
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../core/app_colors.dart'; // Assuming AppColors is defined

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

  // --- UI STATE ---
  bool _isLoading = false;
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  // --- LOGGER INSTANCE ---
  final Logger _logger = Logger();

  // The register URL from your API documentation
  final String registerUrl = "http://msa.merkuz.com:3636/users/register";

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showToast(String message, {Color bgColor = Colors.red}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: bgColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _signUp() async {
    // 1. FORM VALIDATION
    if (!_formKey.currentState!.validate()) {
      _logger.w("Form validation failed.");
      return;
    }

    // 2. OFFLINE CHECK
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _logger.w("Sign-up attempt while offline.");
      _showToast("❌ You are offline. Please check your internet connection.");
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    _logger.i('--- SIGN UP PROCESS STARTED ---');

    // 3. CORRECTED REQUEST BODY
    final requestBody = {
      "username": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
    };
    final jsonBody = jsonEncode(requestBody);

    _logger.i('Request URL: $registerUrl');
    _logger.d('Request JSON Body: $jsonBody');

    try {
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonBody,
      );

      _logger.i("Status Code Received: ${response.statusCode}");
      _logger.d("Response Body Received: ${response.body}");
      final responseData = jsonDecode(response.body);

      // 4. SUCCESS HANDLING (Status Code 201)
      if (response.statusCode == 201) {
        _logger.i('Registration successful. Awaiting email verification.');

        // Use the message from the API response for the toast
        final apiMessage = responseData["message"] ??
            "Registration successful! Please check your email for a verification code.";
        _showToast(apiMessage, bgColor: Colors.green);

        // *** CHANGE: NAVIGATE TO VERIFICATION PAGE ***
        // Navigate to the new verification page and pass the user's email.
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationPage(
                email: _emailController.text.trim(),
              ),
            ),
          );
        }
      } else {
        // 5. ENHANCED ERROR HANDLING
        String errorMessage = "An unexpected error occurred.";
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData["message"] ??
              responseData["error"] ??
              "Could not read error message.";
        }

        _logger.e('API Error: ${response.statusCode} - $errorMessage');

        // Provide user-friendly messages based on status code
        switch (response.statusCode) {
          case 400:
            _showToast("❌ Please check the details you entered.");
            break;
          case 409: // Conflict
            _showToast("❌ This email address is already in use.");
            break;
          case 500:
            _showToast(
                "🔧 There's a problem on our end. Please try again later.");
            break;
          default:
            _showToast("❌ Error ${response.statusCode}: $errorMessage");
        }
      }
    } on http.ClientException catch (e, st) {
      _logger.e('Network ClientException:', error: e, stackTrace: st);
      _showToast("⚠️ You appear to be offline. Please check your connection.");
    } catch (e, st) {
      _logger.f('Fatal Unhandled Exception:', error: e, stackTrace: st);
      _showToast("⚠️ An unexpected error occurred: $e");
    } finally {
      _logger.i('--- SIGN UP PROCESS ENDED ---');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: size.height * 0.05),
                Text(
                  "Create Your Account",
                  style: TextStyle(
                    fontSize: size.width * 0.08,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: size.height * 0.015),
                Text(
                  "Begin your journey with Minber Super App and enjoy effortless access.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: size.width * 0.04),
                ),
                SizedBox(height: size.height * 0.04),
                // Name Field (corresponds to 'username')
                _buildTextField(
                  size,
                  controller: _nameController,
                  label: "Username",
                  hint: "Enter your full name or username",
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return "Username is required";
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.02),
                // Email Field
                _buildTextField(
                  size,
                  controller: _emailController,
                  label: "Email",
                  hint: "Enter your email address",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return "Email is required";
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                      return "Enter a valid email";
                    return null;
                  },
                ),
                SizedBox(height: size.height * 0.02),

                // **** PASSWORD FIELD WITH EYE ICON ****
                _buildTextField(
                  size,
                  controller: _passwordController,
                  label: "Password",
                  hint: "Create a password",
                  icon: Icons.lock,
                  obscure: _isPasswordObscured,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Password is required";
                    if (value.length < 6)
                      return "Password must be at least 6 characters";
                    return null;
                  },
                  // This is the eye icon implementation
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordObscured
                        ? Icons.visibility_off
                        : Icons.visibility),
                    color: AppColors.primary.withOpacity(0.7),
                    onPressed: () => setState(
                        () => _isPasswordObscured = !_isPasswordObscured),
                  ),
                ),
                SizedBox(height: size.height * 0.02),

                // **** CONFIRM PASSWORD FIELD WITH EYE ICON ****
                _buildTextField(
                  size,
                  controller: _confirmPasswordController,
                  label: "Confirm Password",
                  hint: "Confirm your password",
                  icon: Icons.lock_reset,
                  obscure: _isConfirmPasswordObscured,
                  validator: (value) {
                    if (value != _passwordController.text)
                      return "Passwords do not match";
                    return null;
                  },
                  // This is the eye icon implementation
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordObscured
                        ? Icons.visibility_off
                        : Icons.visibility),
                    color: AppColors.primary.withOpacity(0.7),
                    onPressed: () => setState(() => _isConfirmPasswordObscured =
                        !_isConfirmPasswordObscured),
                  ),
                ),
                SizedBox(height: size.height * 0.04),
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: size.height * 0.07,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Sign Up",
                            style: TextStyle(
                                fontSize: size.width * 0.045,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                SizedBox(height: size.height * 0.03),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        "Login",
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // This helper widget now correctly handles the suffixIcon
  Widget _buildTextField(
    Size size, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
        suffixIcon: suffixIcon, // The IconButton is passed here
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.height * 0.02,
        ),
      ),
    );
  }
}
