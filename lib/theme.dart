import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF446CB3);
  static const primaryDark = Color(0xFF3A539B);
  static const googleBlue = Color(0xFF4885ED);
  static const fbBlue = Color(0xFF3B5998);
  static const termGray = Color(0xFF616161);
  static const callGreen = Color(0xFF17B739);
  static const accentPanel = Color(0x48446CB3);
  static const signupPanel = Color(0x48F5AB35);
  static const lightWhite = Color(0x48BFBFBF);
  static const drawerGray = Color(0xFFCFCFCF);
}

ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: UnderlineInputBorder(),
    ),
    useMaterial3: true,
  );
}
