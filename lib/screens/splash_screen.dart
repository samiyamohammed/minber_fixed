// // lib/screens/splash_screen.dart (New File - Ready to Paste)

// import 'package:flutter/material.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:provider/provider.dart';
// import '../providers/user_provider.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _initializeAppAndNavigate();
//   }

//   Future<void> _initializeAppAndNavigate() async {
//     // We already requested permission in main.dart, so we can just get the token.
//     final String? fcmToken = await FirebaseMessaging.instance.getToken();
//     debugPrint("✅ Fetched FCM Token on Splash Screen: $fcmToken");

//     // Check if the widget is still in the tree before navigating
//     if (!mounted) return;

//     final prefs = await SharedPreferences.getInstance();
//     final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
//     final bool seenOnboarding = prefs.getBool('onboarding_complete') ?? false;

//     String targetRoute;

//     if (isLoggedIn) {
//       // SCENARIO A: User is logged in.
//       targetRoute = '/home';
//       // Update the token on the server in the background.
//       if (fcmToken != null) {
//         // Use context.read since this is a one-off action in initState.
//         context.read<UserProvider>().updateDeviceToken(fcmToken);
//       }
//     } else if (seenOnboarding) {
//       // SCENARIO B: User has seen onboarding but isn't logged in.
//       targetRoute = '/login';
//     } else {
//       // SCENARIO C: First-time user.
//       targetRoute = '/onboarding';
//     }

//     debugPrint("➡️ Splash Screen → navigating to $targetRoute");
//     // Navigate to the determined route, replacing the splash screen in the stack.
//     Navigator.pushReplacementNamed(context, targetRoute);
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This UI should look identical to your native splash screen for a seamless transition.
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Use your app's logo
//             Image.asset('assets/images/minber.jpg', height: 100),
//             const SizedBox(height: 20),
//             const CircularProgressIndicator(),
//             const SizedBox(height: 10),
//             Text(
//               "Initializing...",
//               style: Theme.of(context).textTheme.bodyMedium,
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
