import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // --- UI STATE ---
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isPasswordObscured = true;

  // --- LOGGER INSTANCE ---
  final Logger _logger = Logger();

  final String loginUrl = "http://msa.merkuz.com:3636/users/login";

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('savedEmail');
    final savedPassword = prefs.getString('savedPassword');
    if (savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
      _logger.i("Loaded saved credentials for user: $savedEmail");
    }
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

  // Future<void> _handleCredentialsAfterLogin(String token) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('accessToken', token);
  //   await prefs.setBool('isLoggedIn', true);

  //   if (_rememberMe) {
  //     // Save credentials if "Remember Me" is checked
  //     await prefs.setString('savedEmail', _emailController.text.trim());
  //     await prefs.setString('savedPassword', _passwordController.text.trim());
  //     _logger.i("Credentials saved for ${_emailController.text.trim()}.");
  //   } else {
  //     // Clear any previously saved credentials if unchecked
  //     await prefs.remove('savedEmail');
  //     await prefs.remove('savedPassword');
  //     _logger.i("Saved credentials cleared.");
  //   }
  // }
  // In login_page.dart...

  Future<void> _handleCredentialsAfterLogin(String token, String userId) async {
    // <-- ADD userId here
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', token);
    await prefs.setString(
      'userId',
      userId,
    ); // <-- ADD THIS LINE to save the user ID
    await prefs.setBool('isLoggedIn', true);

    if (_rememberMe) {
      await prefs.setString('savedEmail', _emailController.text.trim());
      await prefs.setString('savedPassword', _passwordController.text.trim());
      _logger.i(
        "Credentials and userId saved for ${_emailController.text.trim()}.",
      );
    } else {
      await prefs.remove('savedEmail');
      await prefs.remove('savedPassword');
      _logger.i("Saved credentials cleared.");
    }
  }

  Future<void> _login() async {
    // 1. FORM VALIDATION
    if (!_formKey.currentState!.validate()) {
      _logger.w("Form validation failed.");
      return;
    }

    // 2. OFFLINE CHECK
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _logger.w("Login attempt while offline.");
      _showToast("❌ You are offline. Please check your internet connection.");
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    _logger.i('--- LOGIN PROCESS STARTED ---');

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final response = await http
          .post(
            Uri.parse(loginUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 15));

      _logger.i("Status Code Received: ${response.statusCode}");
      _logger.d("Response Body Received: ${response.body}");

      // 3. SUCCESS HANDLING
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['accessToken'];
        final userId = data['user']?['id'];

        if (token != null &&
            token.isNotEmpty &&
            userId != null &&
            userId.isNotEmpty) {
          await _handleCredentialsAfterLogin(
            token,
            userId,
          ); // <-- Pass userId here
          _showToast("Login Successful 🎉", bgColor: Colors.green);
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        } else {
          _logger.e(
            "Login succeeded (Status ${response.statusCode}) but token was missing.",
          );
          _showToast("Login failed: Response from server was invalid.");
        }
      } else {
        // 4. ENHANCED ERROR HANDLING
        String errorMessage = "An unknown error occurred.";
        try {
          final responseData = jsonDecode(response.body);
          errorMessage = responseData["message"] ?? "Invalid credentials.";
        } catch (_) {
          errorMessage = response.reasonPhrase ?? "Failed to process request.";
        }

        _logger.e('API Error: ${response.statusCode} - $errorMessage');

        switch (response.statusCode) {
          case 401: // Unauthorized
            _showToast("❌ Invalid email or password.");
            break;
          case 500:
            _showToast(
              "🔧 There's a problem on our end. Please try again later.",
            );
            break;
          default:
            _showToast("❌ Error ${response.statusCode}: $errorMessage");
        }
      }
    } on TimeoutException {
      _logger.w("Network timeout during login.");
      _showToast(
        "⚠️ The server is taking too long to respond. Please try again.",
        bgColor: Colors.orange,
      );
    } on http.ClientException catch (e) {
      _logger.e("Network ClientException during login:", error: e);
      _showToast(
        "⚠️ Could not connect to the server. Please check your connection.",
      );
    } catch (e, st) {
      _logger.f(
        "Fatal Unhandled Exception during login:",
        error: e,
        stackTrace: st,
      );
      _showToast("An unexpected error occurred: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _logger.i('--- LOGIN PROCESS ENDED ---');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.1),
                  Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: size.width * 0.08,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: size.height * 0.05),

                  /// Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(size).copyWith(
                      labelText: "Email",
                      prefixIcon: Icon(
                        Icons.email,
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Please enter your email";
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                        return "Enter a valid email";
                      return null;
                    },
                  ),
                  SizedBox(height: size.height * 0.02),

                  /// Password with Eye Icon
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isPasswordObscured, // Bind to state variable
                    decoration: _inputDecoration(size).copyWith(
                      labelText: "Password",
                      prefixIcon: Icon(
                        Icons.lock,
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                      // This is the eye icon implementation
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscured
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        color: AppColors.primary.withOpacity(0.7),
                        onPressed: () => setState(
                          () => _isPasswordObscured = !_isPasswordObscured,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Please enter your password";
                      if (value.length < 6)
                        return "Password must be at least 6 characters";
                      return null;
                    },
                  ),
                  SizedBox(height: size.height * 0.01),

                  /// Remember me + Forgot password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) =>
                                setState(() => _rememberMe = value ?? false),
                          ),
                          const Text("Remember me"),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _showToast("Forgot Password clicked"),
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.03),

                  /// Login Button
                  SizedBox(
                    width: double.infinity,
                    height: size.height * 0.07,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Login",
                              style: TextStyle(
                                fontSize: size.width * 0.045,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),

                  /// Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.1),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(Size size) {
    return InputDecoration(
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
    );
  }
}
