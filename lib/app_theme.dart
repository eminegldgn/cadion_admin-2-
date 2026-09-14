import 'package:flutter/material.dart';

class AdminColors {
  static const Color background = Color(0xFF030B18);
  static const Color surface = Color(0xFF0B1728);
  static const Color surfaceSecondary = Color(0xFF111F33);

  static const Color primary = Color(0xFF1597FF);
  static const Color primaryLight = Color(0xFF32C7FF);

  static const Color success = Color(0xFF22D69A);
  static const Color warning = Color(0xFFFFB547);
  static const Color error = Color(0xFFFF5C75);

  static const Color textPrimary = Color(0xFFF4F7FB);
  static const Color textSecondary = Color(0xFF9EACC0);
  static const Color textMuted = Color(0xFF65758B);

  static const Color border = Color(0xFF22324A);
}

class AdminTheme {
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AdminColors.primary,
      brightness: Brightness.dark,
      surface: AdminColors.surface,
      error: AdminColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AdminColors.background,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',

      appBarTheme: const AppBarTheme(
        backgroundColor: AdminColors.background,
        foregroundColor: AdminColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AdminColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.surface,
        hintStyle: const TextStyle(
          color: AdminColors.textMuted,
        ),
        prefixIconColor: AdminColors.primaryLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AdminColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AdminColors.primary,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AdminColors.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AdminColors.error,
            width: 1.4,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(
            double.infinity,
            54,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: AdminColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: AdminColors.border,
          ),
        ),
      ),

      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AdminColors.surface,
        indicatorColor: Color(0x332197F3),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AdminColors.surfaceSecondary,
        contentTextStyle: const TextStyle(
          color: AdminColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dividerColor: AdminColors.border,
    );
  }
}