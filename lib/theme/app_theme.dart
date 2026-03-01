import 'package:flutter/material.dart';

/// Minimalistic light theme configuration
class AppTheme {
  // Ultra-light color palette (minimalistic)
  static const Color _primary = Color(0xFF1F1F1F); // Charcoal (very dark)
  static const Color _secondary = Color(0xFF757575); // Medium gray
  static const Color _tertiary = Color(0xFFC0C0C0); // Light gray
  static const Color _background = Color(0xFFFAFAFA); // Almost white
  static const Color _surface = Color(0xFFFFFFFF); // Pure white
  static const Color _border = Color(0xFFE8E8E8); // Ultra-light border
  static const Color _error = Color(0xFFD32F2F); // Soft red
  static const Color _divider = Color(0xFFF0F0F0); // Divider gray

  /// Minimalistic light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Minimalistic color scheme
      colorScheme: const ColorScheme.light(
        primary: _primary,
        secondary: _secondary,
        tertiary: _tertiary,
        surface: _surface,
        surfaceBright: _background,
        error: _error,
        outline: _border,
        outlineVariant: _divider,
      ),

      scaffoldBackgroundColor: _background,

      // Minimal AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _primary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: _primary, size: 22),
      ),

      // Minimal button styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Minimal outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _border, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Minimal filled button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Minimal input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _error, width: 1.5),
        ),
        labelStyle: const TextStyle(
          color: _secondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          color: _primary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        prefixIconColor: _secondary,
        suffixIconColor: _secondary,
        hintStyle: const TextStyle(color: _tertiary, fontSize: 13),
        helperStyle: const TextStyle(color: _tertiary, fontSize: 12),
      ),

      // Minimal text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          color: _primary,
          letterSpacing: 0,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w300,
          color: _primary,
          letterSpacing: 0,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: _primary,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: _primary,
          letterSpacing: 0,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: _primary,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _primary,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _primary,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _primary,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: _primary,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _secondary,
          letterSpacing: 0,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: _tertiary,
          letterSpacing: 0,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _primary,
          letterSpacing: 0.5,
        ),
      ),

      // Minimal icon theme
      iconTheme: const IconThemeData(color: _primary, size: 22),

      // Minimal card styling
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _border, width: 1),
        ),
      ),

      // Minimal divider
      dividerTheme: const DividerThemeData(
        color: _divider,
        thickness: 1,
        space: 1,
        indent: 0,
        endIndent: 0,
      ),

      // Minimal chip theme
      chipTheme: ChipThemeData(
        backgroundColor: _surface,
        selectedColor: _primary,
        labelStyle: const TextStyle(
          color: _primary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: _border),
        ),
        side: const BorderSide(color: _border, width: 1),
      ),

      // Minimal FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Minimal SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _primary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 0,
      ),
    );
  }
}
