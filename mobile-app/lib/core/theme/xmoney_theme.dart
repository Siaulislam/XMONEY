import 'package:flutter/material.dart';

class XmoneyTheme {
  static const navy = Color(0xFF0B1F3A);
  static const navyDeep = Color(0xFF071526);
  static const blue = Color(0xFF1A4B8C);
  static const teal = Color(0xFF0D9488);
  static const gold = Color(0xFFC9A227);
  static const surface = Color(0xFFF5F7FA);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: teal,
        primary: navy,
        secondary: teal,
        surface: surface,
      ),
      fontFamily: 'Roboto',
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: navyDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
