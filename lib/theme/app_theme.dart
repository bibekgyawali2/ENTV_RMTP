import 'package:flutter/material.dart';

/// Application theme configuration
class AppTheme {
  // Light color palette
  static const Color _darkText = Color(0xFF1A1A1A);
  static const Color _mediumText = Color(0xFF6B6B6B);
  static const Color _lightText = Color(0xFFB0B0B0);
  static const Color _background = Color(0xFFFBFBFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFEEEEEE);
  static const Color _error = Color(0xFFE53935);

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme with very light colors
      colorScheme: const ColorScheme.light(
        primary: _darkText,
        secondary: _mediumText,
        surface: _surface,
        surfaceBright: _background,
        error: _error,
        outline: _border,
      ),

      scaffoldBackgroundColor: _background,

      // AppBar styling
      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _darkText,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: _darkText, size: 24),
      ),

      // Button styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkText,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ),

      // Input field styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkText, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error, width: 1),
        ),
        labelStyle: const TextStyle(
          color: _mediumText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          color: _darkText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: _mediumText,
        hintStyle: const TextStyle(color: _lightText, fontSize: 14),
      ),

      // Text styling
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: _darkText,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: _darkText,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: _darkText,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: _darkText,
          letterSpacing: -0.2,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _darkText,
          letterSpacing: -0.1,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _mediumText,
          letterSpacing: -0.1,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: _lightText,
          letterSpacing: -0.1,
        ),
      ),

      // Icon styling
      iconTheme: const IconThemeData(color: _darkText, size: 24),

      // Card styling
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border, width: 1),
        ),
      ),

      // Divider styling
      dividerTheme: const DividerThemeData(
        color: _border,
        thickness: 1,
        space: 1,
      ),

      // FloatingActionButton styling
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkText,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // SnackBar styling
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkText.withOpacity(0.9),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
