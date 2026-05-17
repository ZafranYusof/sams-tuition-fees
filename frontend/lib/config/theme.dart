import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SAMsTheme {
  // ─── Colors (refined editorial palette) ───
  // Ink navy base, with a warm brass accent — UMPSA-inspired but contemporary.
  static const Color background = Color(0xFF0B1B2C);
  static const Color surface = Color(0xFF12263A);
  static const Color surfaceLight = Color(0xFF1B324A);
  static const Color primary = Color(0xFFC9A961); // brass / muted gold
  static const Color primaryLight = Color(0xFFE3C589);
  static const Color accent = Color(0xFFC9A961);
  static const Color accentDark = Color(0xFFA98742);
  static const Color textPrimary = Color(0xFFF5EFE3); // warm paper
  static const Color textSecondary = Color(0xFFB7C2CD);
  static const Color textMuted = Color(0xFF7A8A9A);
  static const Color border = Color(0x1AF5EFE3);
  static const Color success = Color(0xFF6FB58A);
  static const Color error = Color(0xFFE08584);
  static const Color warning = Color(0xFFE0B470);

  // Convenience for editorial accents (do not break old API)
  static const Color ink = Color(0xFF0B1B2C);
  static const Color paper = Color(0xFFF5EFE3);
  static const Color brass = Color(0xFFC9A961);

  static TextTheme _buildDarkTextTheme() {
    final serif = GoogleFonts.fraunces(
      color: textPrimary,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.5,
    );
    final sans = GoogleFonts.inter(color: textPrimary);
    return TextTheme(
      displayLarge: serif.copyWith(fontSize: 40, height: 1.05),
      displayMedium: serif.copyWith(fontSize: 32, height: 1.1),
      headlineLarge: serif.copyWith(fontSize: 28, fontWeight: FontWeight.w500, height: 1.15),
      headlineMedium: serif.copyWith(fontSize: 22, fontWeight: FontWeight.w500),
      headlineSmall: sans.copyWith(fontWeight: FontWeight.w600, fontSize: 17),
      titleLarge: sans.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: sans.copyWith(fontSize: 15.5, height: 1.45),
      bodyMedium: sans.copyWith(color: textSecondary, fontSize: 14, height: 1.5),
      bodySmall: sans.copyWith(color: textMuted, fontSize: 12, height: 1.4),
      labelLarge: sans.copyWith(fontWeight: FontWeight.w600, fontSize: 13.5, letterSpacing: 0.2),
      labelMedium: sans.copyWith(color: textMuted, fontSize: 11.5, letterSpacing: 0.6),
      labelSmall: sans.copyWith(color: textMuted, fontSize: 10.5, letterSpacing: 1.4),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
      ),
      textTheme: _buildDarkTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.fraunces(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: ink,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.5, letterSpacing: 0.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: textMuted),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: border,
    );
  }
}
