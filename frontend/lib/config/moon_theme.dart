import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

/// Pure Moon Design tokens - NO custom branding, NO SAMs editorial overrides.
/// Uses Moon's default colors, typography, and spacing.
class SAMsMoonTheme {
  /// Light theme tokens (Moon defaults)
  static MoonTokens get lightTokens => MoonTokens.light;

  /// Dark theme tokens (Moon defaults)
  static MoonTokens get darkTokens => MoonTokens.dark;

  /// Light Material theme (uses Moon's piccolo as primary)
  static ThemeData get lightTheme {
    final moon = MoonTheme(tokens: MoonTokens.light);
    final colors = moon.tokens.colors;
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.goku,
      primaryColor: colors.piccolo,
      colorScheme: ColorScheme.light(
        primary: colors.piccolo,
        secondary: colors.frieza,
        surface: colors.gohan,
        error: colors.chichi,
        onPrimary: colors.goten,
        onSurface: colors.bulma,
      ),
      extensions: <ThemeExtension<dynamic>>[moon],
    );
  }

  /// Dark Material theme
  static ThemeData get darkTheme {
    final moon = MoonTheme(tokens: MoonTokens.dark);
    final colors = moon.tokens.colors;
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.goku,
      primaryColor: colors.piccolo,
      colorScheme: ColorScheme.dark(
        primary: colors.piccolo,
        secondary: colors.frieza,
        surface: colors.gohan,
        error: colors.chichi,
        onPrimary: colors.goten,
        onSurface: colors.bulma,
      ),
      extensions: <ThemeExtension<dynamic>>[moon],
    );
  }
}
