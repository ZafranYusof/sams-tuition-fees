import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';

class ThemeState {
  final bool isDark;
  ThemeState({this.isDark = true});
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? true;
    state = ThemeState(isDark: isDark);
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final newVal = !state.isDark;
    await prefs.setBool('dark_mode', newVal);
    state = ThemeState(isDark: newVal);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) => ThemeNotifier());

// ─── Light theme: warm paper ground, ink text, brass accent ───
class SAMsLightTheme {
  static const Color background = Color(0xFFF5EFE3); // warm paper
  static const Color surface = Color(0xFFFFFEF9);
  static const Color surfaceLight = Color(0xFFEDE5D4);
  static const Color primary = Color(0xFF0B1B2C); // ink (used as primary action)
  static const Color primaryLight = Color(0xFF12263A);
  static const Color accent = Color(0xFFB28A3E); // brass for light mode
  static const Color textPrimary = Color(0xFF0B1B2C);
  static const Color textSecondary = Color(0xFF4B5A68);
  static const Color textMuted = Color(0xFF8A8273);
  static const Color border = Color(0xFFE3DAC6);
  static const Color success = Color(0xFF3F7D52);
  static const Color error = Color(0xFFB14A48);
  static const Color warning = Color(0xFFB28A3E);

  static TextTheme _buildLightTextTheme() {
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

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
      ),
      textTheme: _buildLightTextTheme(),
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
      cardTheme: CardThemeData(
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
          foregroundColor: SAMsTheme.paper,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14.5, letterSpacing: 0.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primary, width: 1.5)),
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
