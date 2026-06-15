import 'package:flutter/material.dart';

/// SAMs theme shim — uses Moon's color palette (hex hardcoded for const-access).
/// Reference: moon_tokens-0.0.6 MoonColors.dark/light
class SAMsTheme {
  // ─── Moon color palette (dark theme) ───
  // Backgrounds
  static const Color background = Color(0xFF000000); // goku
  static const Color surface = Color(0xFF1F1F1F); // gohan
  static const Color surfaceLight = Color(0xFF292929); // beerus
  // Primary brand (Moon piccolo - purple)
  static const Color primary = Color(0xFF5C33CF);
  static const Color primaryLight = Color(0xFF8B5FFF);
  static const Color accent = Color(0xFF5C33CF);
  static const Color accentDark = Color(0xFF4423A0);
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF); // bulma
  static const Color textSecondary = Color(0xFF94989E); // trunks
  static const Color textMuted = Color(0xFF94989E);
  // Borders
  static const Color border = Color(0xFF292929); // beerus
  // Status
  static const Color success = Color(0xFF49B356); // roshi
  static const Color error = Color(0xFFFF4E64); // chichi
  static const Color warning = Color(0xFFFFB319); // krillin

  // Editorial accents → Moon
  static const Color ink = Color(0xFF000000);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color brass = Color(0xFF5C33CF); // Now piccolo purple

  /// Background — flat Moon black
  static const BoxDecoration premiumBackground = BoxDecoration(
    color: Color(0xFF000000),
  );

  /// Background widget
  static Widget gradientScaffold({required Widget child, bool showGlow = true}) {
    return Container(
      color: const Color(0xFF000000),
      child: child,
    );
  }
}

/// Light theme — Moon defaults
class SAMsLightTheme {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF), // light goku
      primaryColor: const Color(0xFF4D31CC), // light piccolo
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4D31CC),
        secondary: Color(0xFF4D31CC),
        surface: Color(0xFFF6F6F8), // light gohan
        error: Color(0xFFFF4E64),
        onPrimary: Color(0xFFFFFFFF),
        onSurface: Color(0xFF000000),
      ),
    );
  }
}
