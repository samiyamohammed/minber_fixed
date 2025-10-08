import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart'; // Make sure this path is correct
import '../core/app_colors.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the current user's data from the provider
    final user = Provider.of<UserProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showToast("Please enter a valid name.", bgColor: Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final userId = prefs.getString('userId');

    if (token == null || userId == null) {
      _showToast("Authentication error. Please log in again.");
      setState(() => _isLoading = false);
      return;
    }

    // From your Swagger docs: PUT /users/{id} with a "name" field in the body
    final url = Uri.parse('http://msa.merkuz.com:3636/users/$userId');
    final body = jsonEncode({'name': _nameController.text.trim()});

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // SUCCESS: Tell the provider to re-fetch the user data. This updates the UI everywhere.
        await Provider.of<UserProvider>(context, listen: false).fetchUser();
        _showToast("Profile updated successfully!", bgColor: Colors.green);
        if (mounted) Navigator.of(context).pop();
      } else {
        final responseData = jsonDecode(response.body);
        _showToast(
          "Update failed: ${responseData['message'] ?? 'Server error'}",
        );
      }
    } catch (e) {
      _showToast("An error occurred. Please check your connection.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {Color bgColor = Colors.red}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: bgColor,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  // THIS IS THE BUILD METHOD THAT WAS MISSING
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final user = Provider.of<UserProvider>(context, listen: false).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const SizedBox(height: 20),
            // --- Profile Picture Section ---
            Center(
              child: CircleAvatar(
                radius: size.width * 0.15,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  user?.username.isNotEmpty ?? false
                      ? user!.username[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 48,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Name Field ---
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Username",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Username cannot be empty";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // --- Email Field (Read-Only) ---
            TextFormField(
              controller: _emailController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Email Address (cannot be changed)",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Theme.of(context).disabledColor.withOpacity(0.1),
                filled: true,
              ),
            ),
            const SizedBox(height: 40),

            // --- Save Button ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
