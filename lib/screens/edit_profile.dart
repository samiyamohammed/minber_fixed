// // lib/screens/edit_profile_page.dart (No Changes Needed, Final Version)

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../providers/user_provider.dart';

// class EditProfilePage extends StatefulWidget {
//   const EditProfilePage({super.key});

//   @override
//   State<EditProfilePage> createState() => _EditProfilePageState();
// }

// class _EditProfilePageState extends State<EditProfilePage> {
//   final _formKey = GlobalKey<FormState>();
//   late final TextEditingController _nameController;
//   late final TextEditingController _emailController;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     final user = Provider.of<UserProvider>(context, listen: false).user;
//     _nameController = TextEditingController(text: user?.username ?? '');
//     _emailController = TextEditingController(text: user?.email ?? '');
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     super.dispose();
//   }

//   Future<void> _saveProfile() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       await Provider.of<UserProvider>(context, listen: false).updateUserProfile(
//         name: _nameController.text,
//         email: _emailController.text,
//       );

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text("Profile updated successfully!"),
//               backgroundColor: Colors.green),
//         );
//         Navigator.of(context).pop();
//       }
//     } catch (e) {
//       if (mounted) {
//         final errorMessage = e.toString().replaceFirst("Exception: ", "");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text(errorMessage),
//               backgroundColor: Theme.of(context).colorScheme.error),
//         );
//         if (errorMessage.contains("Please log in again")) {
//           Navigator.of(context, rootNavigator: true)
//               .pushNamedAndRemoveUntil('/login', (route) => false);
//         }
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Edit Profile")),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.all(20.0),
//           children: [
//             TextFormField(
//               controller: _nameController,
//               readOnly: _isLoading,
//               decoration: InputDecoration(
//                 labelText: "Full Name",
//                 prefixIcon: const Icon(Icons.person_outline),
//                 border:
//                     OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//               validator: (v) =>
//                   v!.trim().isEmpty ? 'Please enter your name' : null,
//             ),
//             const SizedBox(height: 20),
//             TextFormField(
//               controller: _emailController,
//               readOnly: _isLoading,
//               decoration: InputDecoration(
//                 labelText: "Email Address",
//                 prefixIcon: const Icon(Icons.email_outlined),
//                 border:
//                     OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//               keyboardType: TextInputType.emailAddress,
//               validator: (v) => (v == null || !v.contains('@'))
//                   ? 'Enter a valid email'
//                   : null,
//             ),
//             const SizedBox(height: 40),
//             FilledButton.icon(
//               onPressed: _isLoading ? null : _saveProfile,
//               icon: _isLoading
//                   ? const SizedBox(
//                       width: 24,
//                       height: 24,
//                       child: CircularProgressIndicator(
//                           strokeWidth: 3, color: Colors.white))
//                   : const Icon(Icons.save_as_outlined),
//               label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
//               style: FilledButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 textStyle:
//                     const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
