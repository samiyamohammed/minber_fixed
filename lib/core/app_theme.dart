// // lib/core/app_theme.dart

// import 'package:flutter/material.dart';
// import 'app_colors.dart'; // Import our custom colors

// /// Defines the visual themes (Light & Dark) for the Minber TV Super App.
// class AppThemes {
//   // Prevent instantiation
//   AppThemes._();

//   /// --- LIGHT THEME ---
//   static final ThemeData lightTheme = ThemeData(
//     brightness: Brightness.light,
//     primaryColor: AppColors.primaryBlue,
//     scaffoldBackgroundColor: AppColors.backgroundLight,
//     fontFamily:
//         'Roboto', // Consider adding a professional font like Roboto or Noto Sans
//     appBarTheme: const AppBarTheme(
//       backgroundColor: AppColors.primaryBlue,
//       elevation: 2.0,
//       iconTheme: IconThemeData(color: AppColors.textWhite),
//       titleTextStyle: TextStyle(
//         color: AppColors.textWhite,
//         fontSize: 20.0,
//         fontWeight: FontWeight.w600,
//       ),
//     ),
//     colorScheme: const ColorScheme.light(
//       primary: AppColors.primaryBlue,
//       secondary: AppColors.accentBlue,
//       onPrimary: AppColors.textWhite,
//       onSecondary: AppColors.textWhite,
//       background: AppColors.backgroundLight,
//       onBackground: AppColors.textGrey,
//       surface: AppColors.backgroundLight,
//       onSurface: AppColors.textGrey,
//       error: Colors.redAccent,
//       onError: Colors.white,
//     ),
//     textTheme: const TextTheme(
//       headlineLarge:
//           TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold),
//       bodyLarge: TextStyle(color: AppColors.textGrey),
//       bodyMedium: TextStyle(color: Colors.black54),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: AppColors.primaryBlue,
//         foregroundColor: AppColors.textWhite,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8.0),
//         ),
//       ),
//     ),
//   );

//   /// --- DARK THEME ---
//   static final ThemeData darkTheme = ThemeData(
//     brightness: Brightness.dark,
//     primaryColor: AppColors.primaryBlue,
//     scaffoldBackgroundColor: AppColors.backgroundDark,
//     fontFamily: 'Roboto',
//     appBarTheme: const AppBarTheme(
//       backgroundColor:
//           AppColors.surfaceDark, // A subtle dark background for the app bar
//       elevation: 2.0,
//       iconTheme: IconThemeData(color: AppColors.textWhite),
//       titleTextStyle: TextStyle(
//         color: AppColors.textWhite,
//         fontSize: 20.0,
//         fontWeight: FontWeight.w600,
//       ),
//     ),
//     colorScheme: const ColorScheme.dark(
//       primary: AppColors
//           .accentBlue, // Use the brighter blue for accents in dark mode
//       secondary: AppColors.primaryBlue,
//       onPrimary: AppColors.textGrey,
//       onSecondary: AppColors.textWhite,
//       background: AppColors.backgroundDark,
//       onBackground: AppColors.textWhite,
//       surface: AppColors.surfaceDark,
//       onSurface: AppColors.textWhite,
//       error: Colors.red,
//       onError: Colors.white,
//     ),
//     textTheme: const TextTheme(
//       headlineLarge:
//           TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
//       bodyLarge: TextStyle(color: AppColors.textWhite),
//       bodyMedium: TextStyle(color: Colors.white70),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: AppColors.accentBlue,
//         foregroundColor: AppColors.textGrey, // Dark text on the bright button
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8.0),
//         ),
//       ),
//     ),
//   );
// }
