import 'package:flutter/material.dart';

class XmoneyTheme {
  static const navy = Color(0xFF0B1F3A);
  static const navyDeep = Color(0xFF071526);
  static const blue = Color(0xFF1A4B8C);
  static const teal = Color(0xFF0D9488);
  static const gold = Color(0xFFFFC107);
  static const brandBlack = Color(0xFF000000);
  static const brandWhite = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F7FA);
  static const surfaceDark = Color(0xFF0A0F18);
  static const cardDark = Color(0xFF121A28);

  static ThemeData get light => _build(
        brightness: Brightness.light,
        surface: surface,
        card: Colors.white,
        border: Colors.grey.shade200,
        inputFill: Colors.white,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        surface: surfaceDark,
        card: cardDark,
        border: const Color(0xFF243044),
        inputFill: const Color(0xFF0F1624),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color surface,
    required Color card,
    required Color border,
    required Color inputFill,
  }) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: teal,
        brightness: brightness,
        primary: isDark ? gold : navy,
        secondary: teal,
        surface: surface,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: navyDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      focusColor: gold.withOpacity(0.35),
    );
  }
}
