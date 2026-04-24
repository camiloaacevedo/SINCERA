import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SinceraTheme {
  static const Color background = Color(0xFF121212);
  static const Color accentNeon = Color(0xFFCCFF00);
  static const Color accentOrange = Color(0xFFFF5F1F);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.syne(
        fontWeight: FontWeight.w800,
        color: Colors.white,
        fontSize: 32,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: accentNeon,
      secondary: accentOrange,
      surface: Color(0xFF1E1E1E),
    ),
  );
  static TextStyle get headingStyle => GoogleFonts.syne(
    fontWeight: FontWeight.w800,
    color: Colors.white,
    fontSize: 24,
    letterSpacing: 2,
  );
}
